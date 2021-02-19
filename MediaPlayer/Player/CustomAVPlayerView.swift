//
//  CustomAVPlayerView.swift
//  Eceibs
//
//  Created by sword on 2017/8/8.
//  Copyright © 2017年 sword. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

private let margin: CGFloat = 15
private let barHeight : CGFloat = 35.0
private let fullScreenButtonWidth: CGFloat = 17
private let rateButtonWidth: CGFloat = 35
private let rateListWidth: CGFloat = 100

@objc protocol CustomPlayerViewDelegate: class {
    
    @objc optional func backWithPlayer(player: CustomAVPlayerView)
    
    @objc optional func playWithPlayer(player: CustomAVPlayerView)
    
    @objc optional func pauseWithPlayer(player: CustomAVPlayerView)
    
    @objc optional func playFailedWithPlayer(player: CustomAVPlayerView)
    
    @objc optional func playCancelWithPlayer(player: CustomAVPlayerView)
    
    @objc optional func fullScreen(player: CustomAVPlayerView, fullScreen: Bool)
    
    @objc optional func playFinished(player: CustomAVPlayerView)
    
    @objc optional func playProgress(player: CustomAVPlayerView, currentTime: Double)
    
    @objc optional func playerBarHiddenOrShow(isShow: Bool)
}

class CustomAVPlayerView: UIView {
    
    weak var delegate:CustomPlayerViewDelegate?  //代理
    
    fileprivate let topBar = UIView() //顶部bar
    
    fileprivate let bottomBar = UIView() //底部bar
    
    fileprivate let backButton = UIButton(type: .custom) //返回按钮
    
    fileprivate let numberLabel = UILabel() //索引label
    
    fileprivate let playButton = UIButton(type: .custom) //底部bar上的播放按钮
    
    fileprivate let currentTimeLabel = UILabel() //当前播放时间
    
    fileprivate let videoTimeLabel = UILabel()
    
//    fileprivate let centerPlayBtn = UIButton(type: .custom) //播放器中心播放
    
    fileprivate let fullScreenButton = UIButton(type: .custom) //全屏切换button
    
    fileprivate let durationSlider = AudioSliderView() //进度条
    
    fileprivate var fullscreenVC: PlayerFullScreenViewController?
    
    fileprivate let rateButton = UIButton(type: .custom) //播放语速按钮
    
    fileprivate let qualityButton = UIButton(type: .custom) //播放清晰度按钮
    
    fileprivate var rateList: VideoPlayRateView? ///播放语速table
    
    fileprivate var qualityList: VideoPlayRateView? ///播放清晰度table
    
    fileprivate var activityLoading: UIActivityIndicatorView?
    
    // -------------------------------------------------------------
    fileprivate var littleScreenSuperView: UIView? = nil //非全屏时的父view
    
    var _pageNumberString: String?
    var pageNumberString:String?{
        set{
            _pageNumberString = newValue
            numberLabel.text = _pageNumberString
            numberLabel.sizeToFit()
            numberLabel.frame.origin.x = frame.width - numberLabel.frame.width - 10
        }
        get {
            return _pageNumberString
        }
    }
    
    fileprivate var playStatus: PlayStatus = .pause
    
    fileprivate var mediaPlayer: CustomMediaPlayer?
    
    var url: URL?        //视频url
    
    fileprivate var barIsShow = false  //bar显示
    
    fileprivate var _hiddenTopBar = false
    var hiddenTopBar: Bool{
        get{
            return _hiddenTopBar
        }
        set{
            _hiddenTopBar = newValue
            topBar.isHidden = _hiddenTopBar
            backButton.frame.size.width = screenWidth - 100
        }
    }
    
    fileprivate var beforeSlideIsPlay = true
    
    ///是否允许全屏(
    var allowFullScreen = false {
        didSet{
            if allowFullScreen == true {
                allowShowFullButton = true
            }
        }
    }
    
    ///允许显示全屏按钮
    var allowShowFullButton = false {
        didSet{
            if allowShowFullButton == false {
                fullScreenButton.removeFromSuperview()
            }
        }
    }
    
    ///显示倍速播放
    var showPlayRate = false {
        didSet{
            if showPlayRate {
                if rateButton.superview == nil {
                    addPlayRateBtn()
                }
            } else {
                rateButton.removeFromSuperview()
            }
            
            var videoMinX = frame.width - margin - videoTimeLabel.frame.width
            if allowShowFullButton {
                videoMinX = videoMinX - margin - fullScreenButtonWidth
            }
            if showPlayRate {
                videoMinX = videoMinX - margin - rateButtonWidth
            }
            if showPlayQuality {
                videoMinX = videoMinX - margin - rateButtonWidth
            }
            videoTimeLabel.frame.origin.x = videoMinX
            
            durationSlider.frame.size.width = videoTimeLabel.frame.minX - margin - currentTimeLabel.frame.maxX - margin
        }
    }
    
    ///显示清晰度切换按钮
    var showPlayQuality = false {
        didSet{
            if showPlayQuality {
                if qualityButton.superview == nil {
                    addPlayQualityBtn()
                }
            } else {
                qualityButton.removeFromSuperview()
            }
            var videoMinX = frame.width - margin - videoTimeLabel.frame.width
            if allowShowFullButton {
                videoMinX = videoMinX - margin - fullScreenButtonWidth
            }
            if showPlayRate {
                videoMinX = videoMinX - margin - rateButtonWidth
            }
            if showPlayQuality {
                videoMinX = videoMinX - margin - rateButtonWidth
            }
            videoTimeLabel.frame.origin.x = videoMinX
            
            durationSlider.frame.size.width = videoTimeLabel.frame.minX - margin - currentTimeLabel.frame.maxX - margin
        }
    }
    
    var isFullScreen = false
    
    var isPlayFinished = false
    
    fileprivate var oldFrame: CGRect?
    
    fileprivate var playRate: Float = 1.0
    
    fileprivate var playQuality: VideoQuality = .sd
    
    fileprivate var begainTouchX: CGFloat = 0   //屏幕触摸开始点
    
    ///标记view是否load过
    fileprivate var isLoadView = false
    
    var _videoTitle: String?
    var videoTitle: String?{
        set{
            _videoTitle = newValue
            backButton.setTitle(_videoTitle, for: .normal)
        }
        get{
            return _videoTitle
        }
    }
    
    ///暂停播放时，开始执行，长时间暂停后，视频不能播放，重启播放器
    fileprivate var videoStatusTimer: Timer?
    fileprivate var reStart: Bool = false
    
    ///切换清晰度后，需要seek到之前的播放进度
    fileprivate var position: Double?
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
        if isLoadView == true {
            return
        }
        addView()
        addObserver()
        isLoadView = true
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addObserver() {
        //MARK: 重复注册会引起多次通知
        //播放完成通知
        NotificationCenter.default.addObserver(self, selector: #selector(pause), name: NSNotification.Name(rawValue: audioPlayNotification), object: nil)
        
        //进入后台程序通知
        NotificationCenter.default.addObserver(self, selector: #selector(pause), name: UIApplication.didEnterBackgroundNotification, object: nil)
        
        //后台重新回到程序通知
        NotificationCenter.default.addObserver(self, selector: #selector(pause), name: UIApplication.didBecomeActiveNotification, object: nil)
        
    }
    
    func addView() {
        topBar.frame = CGRect(x: 0, y: 0, width: frame.width, height: barHeight)
        topBar.autoresizingMask.insert(.flexibleWidth)
        topBar.autoresizingMask.insert(.flexibleBottomMargin)
        addSubview(topBar)
        
        topBar.isHidden = hiddenTopBar
        
        topBar.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        backButton.contentHorizontalAlignment = .left
        backButton.setTitleColor(.white, for: .normal)
        backButton.setImage(UIImage(named: "navigation_comment_back"), for: .normal)
        backButton.addTarget(self, action: #selector(back), for: .touchUpInside)
        backButton.frame = CGRect(x: 10, y: 0, width: frame.width - 100, height: barHeight)
        backButton.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        backButton.titleLabel?.lineBreakMode = .byTruncatingTail
        backButton.setTitle(videoTitle, for: .normal)
        topBar.addSubview(backButton)
        
        numberLabel.font = UIFont.systemFont(ofSize: 14.0)
        numberLabel.textColor = .white
        numberLabel.textAlignment = .right
        numberLabel.text = pageNumberString
        numberLabel.sizeToFit()
        numberLabel.frame = CGRect(x: frame.width - numberLabel.frame.width - 10, y: (topBar.frame.height - numberLabel.frame.height)/2, width: numberLabel.frame.width, height: numberLabel.frame.height)
        numberLabel.autoresizingMask.insert(.flexibleLeftMargin)
        topBar.addSubview(numberLabel)
        
        bottomBar.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        bottomBar.autoresizingMask.insert(.flexibleWidth)
        bottomBar.autoresizingMask.insert(.flexibleTopMargin)
        bottomBar.frame = CGRect(x: 0, y: frame.height - barHeight, width: frame.width, height: barHeight)
        addSubview(bottomBar)
        
        if allowShowFullButton {
            addFullButton()
        }
        
        if showPlayRate {
            addPlayRateBtn()
        }
        
        if showPlayQuality {
            addPlayQualityBtn()
        }
        
        playButton.frame = CGRect(x: margin, y: 0, width: fullScreenButtonWidth, height: barHeight)
        playButton.setImage(UIImage(named: "moviePlayer_pause"), for: .normal)
        playButton.setImage(UIImage(named: "moviePlayer_play"), for: .selected)
        playButton.addTarget(self, action: #selector(playButtonTap), for: .touchUpInside)
        playButton.isSelected = !(playStatus == .play)
        playButton.isHidden = true
        bottomBar.addSubview(playButton)
        
        currentTimeLabel.font = UIFont.systemFont(ofSize: 12)
        currentTimeLabel.textColor = .white
        currentTimeLabel.textAlignment = .center
        currentTimeLabel.text = "00:00"
        currentTimeLabel.sizeToFit()
        currentTimeLabel.frame = CGRect(x: playButton.frame.maxX + margin, y: 0, width: currentTimeLabel.frame.width, height: barHeight)
        currentTimeLabel.autoresizingMask.insert(.flexibleRightMargin)
        bottomBar.addSubview(currentTimeLabel)
        
        videoTimeLabel.font = UIFont.systemFont(ofSize: 12)
        videoTimeLabel.textColor = .white
        videoTimeLabel.textAlignment = .center
        videoTimeLabel.text = "00:00"
        videoTimeLabel.sizeToFit()
        var minX: CGFloat = frame.width - margin - videoTimeLabel.frame.width
        if allowShowFullButton {
            minX = minX - margin - fullScreenButtonWidth
        }
        if showPlayRate {
            minX = minX - margin - rateButtonWidth
        }
        if showPlayQuality {
            minX = minX - margin - rateButtonWidth
        }
        videoTimeLabel.frame = CGRect(x: minX, y: 0, width: videoTimeLabel.frame.width, height: barHeight)
        videoTimeLabel.autoresizingMask.insert(.flexibleLeftMargin)
        bottomBar.addSubview(videoTimeLabel)
        
        durationSlider.sliderType = .video
        durationSlider.thumbStyle = .round
        durationSlider.value = 0
        durationSlider.slider.isContinuous = false
        durationSlider.frame = CGRect(x: currentTimeLabel.frame.maxX + margin, y: 0, width: videoTimeLabel.frame.minX - margin - currentTimeLabel.frame.maxX - margin , height: barHeight)
        durationSlider.autoresizingMask.insert(.flexibleWidth)
        durationSlider.autoresizingMask.insert(.flexibleBottomMargin)
        durationSlider.backgroundColor = .clear
        bottomBar.addSubview(durationSlider)
        durationSlider.slider.addTarget(self, action: #selector(sliderValueChange), for: .valueChanged)
        durationSlider.slider.addTarget(self, action: #selector(sliderTouchDown), for: .touchDown)
        durationSlider.slider.addTarget(self, action: #selector(sliderTouchDown), for: .touchUpInside)
        durationSlider.slider.addTarget(self, action: #selector(sliderTouchDown), for: .touchUpOutside)
        durationSlider.slider.touchCancel = { [weak self] in
            guard let this = self else { return }
            
            this.sliderChangePlay()
            this.sliderTouchEnd()
        }
        
//        bottomBar.alpha = 0
        
//        centerPlayBtn.setImage(UIImage(named: "player_pause"), for: .normal)
//        centerPlayBtn.setImage(UIImage(named: "player_play"), for: .selected)
//        centerPlayBtn.frame.size.width = 57
//        centerPlayBtn.frame.size.height = 57
//        centerPlayBtn.center = CGPoint(x: frame.width/2, y: frame.height/2)
//        centerPlayBtn.autoresizingMask.insert(.flexibleLeftMargin)
//        centerPlayBtn.autoresizingMask.insert(.flexibleRightMargin)
//        centerPlayBtn.autoresizingMask.insert(.flexibleTopMargin)
//        centerPlayBtn.autoresizingMask.insert(.flexibleBottomMargin)
//        centerPlayBtn.addTarget(self, action: #selector(playButtonTap), for: .touchUpInside)
//        centerPlayBtn.isSelected = !(playStatus == .play)
//        centerPlayBtn.isHidden = true
//        addSubview(centerPlayBtn)
    }
    
    private func addFullButton() {
        fullScreenButton.setImage(UIImage(named: "moviePlayer_fullscreen"), for: .normal)
        fullScreenButton.addTarget(self, action: #selector(fullScreen), for: .touchUpInside)
        fullScreenButton.imageView?.contentMode = .scaleAspectFit
        fullScreenButton.frame = CGRect(x: frame.width - margin - fullScreenButtonWidth, y: 0, width: fullScreenButtonWidth, height: barHeight)
        fullScreenButton.autoresizingMask.insert(.flexibleLeftMargin)
        bottomBar.addSubview(fullScreenButton)
    }
    
    private func addPlayRateBtn() {
        var playRateBtnFrameX = frame.width - margin - rateButtonWidth
        if allowShowFullButton {
            playRateBtnFrameX = playRateBtnFrameX - margin - fullScreenButtonWidth
        }
        rateButton.frame = CGRect(x: playRateBtnFrameX, y: 0, width: rateButtonWidth, height: barHeight)
        rateButton.addTarget(self, action: #selector(rateButtonTap), for: .touchUpInside)
        rateButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        var str = ""
        switch playRate {
        case 1:
            str = "1.0x"
        case 1.25:
            str = "1.25x"
        case 1.5:
            str = "1.5x"
        default:
            break
        }
        rateButton.setTitle(str, for: .normal)
        bottomBar.addSubview(rateButton)
    }
    
    private func addPlayQualityBtn() {
        var qualityButtonX = frame.width - margin - rateButtonWidth
        if allowShowFullButton {
            qualityButtonX = qualityButtonX - margin - fullScreenButtonWidth
        }
        if showPlayRate {
            qualityButtonX = qualityButtonX - margin - rateButtonWidth
        }
        qualityButton.frame = CGRect(x: qualityButtonX, y: 0, width: rateButtonWidth, height: barHeight)
        qualityButton.addTarget(self, action: #selector(rateButtonTap), for: .touchUpInside)
        qualityButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        var str = ""
        switch playQuality {
        case .ld:
            str = "标清"
        case .sd:
            str = "高清"
        case .hd:
            str = "超清"
        }
        qualityButton.setTitle(str, for: .normal)
        bottomBar.addSubview(qualityButton)
    }
    
    @objc func rateButtonTap(button: UIButton) {
        if rateList == nil {
            rateList = VideoPlayRateView(frame: CGRect(x: 0, y: 0, width: rateListWidth, height: 100))
            rateList!.isHidden = true
            rateList!.rateSelect = { [weak self] rate in
                guard let this = self else { return }
                
                //设置播放速度
                this.playRate = rate
                this.rateButton.setTitle("\(rate)x", for: .normal)
                this.mediaPlayer?.playRate = rate
                this.rateList!.isHidden = true
            }
            rateList!.qualitySelect = { [weak self] type in
                guard let this = self else { return }
                ///设置播放清晰度
                var str = ""
                switch type {
                case .ld:
                    str = "标清"
                case .sd:
                    str = "高清"
                case .hd:
                    str = "超清"
                }
                this.rateList!.isHidden = true
                if type == this.playQuality {
                    ///重复选择无效
                    return
                }
                this.playQuality = type
                this.qualityButton.setTitle(str, for: .normal)
                this.playWithUrl(videoUrl: this.url!, clearHistory: false)
            }
        }
        var x: CGFloat = 0
        if button == rateButton {
            rateList!.loadTableView(rates: [1.0, 1.25, 1.5], selectedRate: playRate)
            x = rateButton.frame.minX
        } else if button == qualityButton {
            rateList!.loadTableView(qualities: ["超清", "高清", "标清"], selectedQuality: qualityButton.titleLabel?.text)
            x = qualityButton.frame.minX
        }
        rateList!.frame.origin = CGPoint(x: x - (rateListWidth - rateButtonWidth)/2, y: frame.height - bottomBar.frame.height - rateList!.frame.height)
        rateList!.isHidden = !rateList!.isHidden
        addSubview(rateList!)
    }
    
    func playWithUrl(videoUrl: URL, clearHistory: Bool = true) {
        url = videoUrl
        
        isPlayFinished = false
        
        if clearHistory {
            position = nil
        }
        
        playStatus = .pause
        
        if videoUrl.absoluteString.count == 0 {
            return
        }
        durationSlider.value = 0
        durationSlider.cacheProgress = 0
        
        showBar()
        printLog(videoUrl)
        
        var urlStr = videoUrl.absoluteString
        
        if videoUrl.absoluteString.contains("localhost") == false && showPlayQuality == true {
            //playerItem = AVPlayerItem(url: self.url!)
            ///非离线视频
            ///一般在url后面追加不同的参数以区分视频的清晰度
            switch playQuality {
            case .ld:
                //urlStr = 标清url
                break
            case .sd:
                //urlStr = 高清url
                break
            case .hd:
                //urlStr = 超清url
                break
            }
        }
        
        guard let playUrl = URL(string: urlStr) else {
            return
        }
        if mediaPlayer == nil {
            mediaPlayer = CustomMediaPlayer()
            mediaPlayer!.mediaType = .video
            mediaPlayer!.delegate = self
            mediaPlayer!.statusDelegate = self
        }
        mediaPlayer!.playWithUrl(url: playUrl)
        mediaPlayer!.playerAddToSuperView(view: self)
//        centerPlayBtn.isHidden = true
        playButton.isHidden = true
//        addSubview(centerPlayBtn)
        ratePlay()
        showActivityLoading(view: self)
        
        bringSubviewToFront(topBar)
        bringSubviewToFront(bottomBar)
        
        if let pos = position {
            mediaPlayer!.playerSeekTo(time: Float(pos), finish:{ [weak self] in
                guard let this = self else { return }
                
                this.position = nil
            })
            return
        }
        
    }
    
    func ratePlay() {
        videoStatusTimer?.invalidate()
        videoStatusTimer = nil
        if reStart {
            reStart = false
            playWithUrl(videoUrl: url!, clearHistory: false)
            return
        }
        
        if let pl = mediaPlayer {
            pl.play()
            pl.playRate = self.playRate
        }
    }
    
    //seek到某个时间点
    func seekTo(time: Float) {
        mediaPlayer!.playerSeekTo(time: time, finish:{})
    }
    
    ///根据slider的value播放（拖动快进或快退）
    private func sliderChangePlay() {
        mediaPlayer!.playerSeekTo(time: Float(durationSlider.slider.value), finish:{})
    }
    
    //MARK: - UISlider taget
    ///（当slider重写touchend方法且isContinuous属性为false时 valueChange不会调用）
    @objc func sliderValueChange(slider: UISlider) {
        sliderChangePlay()
    }
    
    @objc func sliderTouchDown(slider: UISlider) {
        showBar()
        pause()
    }
    
    func sliderTouchEnd() {
        timerHiddenBar()
        
        if beforeSlideIsPlay == true {
            ratePlay()
        }
    }
    
    ///播放按钮状态
    private func playButtonStatus(selected: Bool) {
//        centerPlayBtn.isSelected = selected
        playButton.isSelected = selected
    }
    
    func applicationDidBecomeActive() {
        pause()
    }
    
    @objc func back()  {
        //pause()
        delegate?.backWithPlayer?(player: self)
    }
    
    //MARK: 暂停或开始播放
    //暂停
    @objc func pause() {
        printLog("pause")
        playButtonStatus(selected: true)
        mediaPlayer?.pause()
        //startTimer()
    }
    
    
    //停止
    func stop() {
        if playStatus == .cancel {
            return
        }
        playButtonStatus(selected: true)
        mediaPlayer?.stop()
    }
    
    func play() {
        if playStatus == .pause && isPlayFinished == false {
            mediaPlayer?.play()
            timerHiddenBar()
        }
    }
    
    @objc private func playButtonTap() {
        showBar()
        timerHiddenBar()
        playOrPause()
    }
    
    @objc func playOrPause() {
        //暂停时点击则开始播放，播放时则点击暂停
        if playStatus != .play {
            //如果已经播放完成，岀再次点击，从头开始播放
            if isPlayFinished == true {
                isPlayFinished = false
                mediaPlayer!.playerSeekTo(time: 0, finish:{()in
                })
            }
            playButtonStatus(selected: false)
            ratePlay()
        }else{
            pause()
        }
    }
    
    private func startTimer() {
        if videoStatusTimer == nil {
            ///如果60s之后仍然在暂停状态，下一次点击播放的时候则重启视频
            videoStatusTimer = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(getVideoStatus), userInfo: nil, repeats: false)
        }
    }
    
    @objc private func getVideoStatus() {
        reStart = true
        
        videoStatusTimer?.invalidate()
        videoStatusTimer = nil
    }
    
    func showBar() {
        barIsShow = true
        delegate?.playerBarHiddenOrShow?(isShow: barIsShow)
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        UIView.animate(withDuration: 0.3, animations: { [weak self] in
            guard let this = self else { return }
            
            this.topBar.alpha = 1
            this.bottomBar.alpha = 1
//            this.centerPlayBtn.alpha = 1
        })
    }
    
    @objc func hiddenBar() {
        barIsShow = false
        delegate?.playerBarHiddenOrShow?(isShow: barIsShow)
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        UIView.animate(withDuration: 0.3, animations: { [weak self] in
            guard let this = self else { return }
            
            this.topBar.alpha = 0
            this.bottomBar.alpha = 0
//            if this.playStatus == .play {
//                this.centerPlayBtn.alpha = 0
//            }
            this.rateList?.isHidden = true
        })
    }
    
    func timerHiddenBar() {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        if barIsShow {
            perform(#selector(hiddenBar), with: self, afterDelay: 3.0)
        }
    }
    
    //触摸屏幕前，记录一下视频的播放状态
    func playerStatus() {
        if playStatus != .play {
            beforeSlideIsPlay = false
        } else {
            beforeSlideIsPlay = true
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        
        rateList?.isHidden = true
        let touch = touches.first
        if touch?.view != self {
            return
        }
        
        barIsShow ? hiddenBar() : showBar()
        //记录点击的点
        begainTouchX = (touch?.location(in: touch?.view).x)!
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let player = mediaPlayer else { return }
        super.touchesMoved(touches, with: event)
        
        let touch = touches.first
        if touch?.view != self {
            return
        }
        
        if (touch?.location(in: touch?.view).x) == begainTouchX {
            return
        }
        
        playerStatus()
        showBar()
        
        if player.playerItem?.status != .readyToPlay {
            return
        }
        
        let totalDuration = player.getTotalTime()
        
        let currentPlayTime = player.getCurrentTime()
        
        let offSetX = (touch?.location(in: touch?.view).x)! - begainTouchX
        
        let jumpTime = (Float(totalDuration) / Float(self.frame.size.width - 100)) * (Float(abs(offSetX)) / Float(UIScreen.main.scale));
        
        var currentTime:Double = 0
        
        if offSetX > 0 {
            currentTime = currentPlayTime + Double(jumpTime)
        } else if(offSetX < 0) {
            currentTime = currentPlayTime - Double(jumpTime)
        } else {
            return
        }
        
        pause()
        mediaPlayer!.playerSeekTo(time: Float(currentTime), finish:{})
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        timerHiddenBar()
        let touch = touches.first
        if touch?.view != self {
            return
        }
        
        if (touch?.location(in: touch?.view).x) == begainTouchX {
            return
        }
        
        if beforeSlideIsPlay == false {
            ratePlay()
        }
        
        begainTouchX = 0
    }
    
    @objc func fullScreen() {
        if allowFullScreen == false {
            delegate?.fullScreen?(player: self, fullScreen: isFullScreen)
            bottomBarFrameChange(fullScreen: isFullScreen)
            return
        }
        if isFullScreen {
            playViewShrink()
        } else {
            playViewFullScreen()
        }
        isFullScreen = !isFullScreen
        
        delegate?.fullScreen?(player: self, fullScreen: isFullScreen)
        bottomBarFrameChange(fullScreen: isFullScreen)
    }
    
    //由全屏变为非全屏
    func playViewShrink() {

        let orientationTarget = UIInterfaceOrientation.portrait.rawValue
        UIDevice.current.setValue(orientationTarget, forKey: "orientation")
        
        //fullscreenVC?.isLandscape = false
        fullscreenVC?.view.removeFromSuperview()
        fullscreenVC = nil
        littleScreenSuperView?.addSubview(self)
        if oldFrame != nil{
            frame = oldFrame!
        }
        
        //mediaPlayer?.playerController?.view.frame = oldFrame!
    }
    
    //由非全屏变为全屏
    func playViewFullScreen() {
        littleScreenSuperView = superview
        oldFrame = frame

        let value = UIInterfaceOrientation.landscapeLeft.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
        
        let window = UIApplication.shared.keyWindow
        if fullscreenVC == nil {
            fullscreenVC = PlayerFullScreenViewController()
        }
        //fullscreenVC?.isLandscape = true
        window?.addSubview((fullscreenVC?.view)!)
        fullscreenVC?.view.addSubview(self)
        
        //frame = CGRect(x: screenSafeAreaInset.left, y: screenSafeAreaInset.top, width: screenWidth - screenSafeAreaInset.left - screenSafeAreaInset.right, height: screenHeight - screenSafeAreaInset.top - screenSafeAreaInset.bottom)
        self.frame = CGRect(x: screenSafeAreaInset.left, y: screenSafeAreaInset.top, width: screenWidth - screenSafeAreaInset.left - screenSafeAreaInset.right, height: screenHeight)
        mediaPlayer?.playerController?.view.frame = bounds
    }
    
    func bottomBarFrameChange(fullScreen: Bool) {
        if fullScreen {
            bottomBar.frame.origin.y = frame.height - (barHeight + screenSafeAreaInset.bottom)
            bottomBar.frame.size.height = barHeight + screenSafeAreaInset.bottom
            return
        }
        bottomBar.frame.origin.y = frame.height - barHeight
        bottomBar.frame.size.height = barHeight
    }
    
    private func getUrlKey(url: String) -> String {
        
        let videoSuffixs = [".m3u8", ".mp4", ".avi", ".wmv", ".rmvb", ".flv", ".mov"]
        
        var suffix = ""
        for str in videoSuffixs {
            if url.contains(str) {
                suffix = str
                break
            }
        }
        if suffix == "" {
            return url
        }
        
        var urlKey: String?
        let array = url.components(separatedBy: suffix)
        if array.count > 0, let first = array.first, first.count > 0 {
            urlKey = "\(first)\(suffix)"
        }
        return urlKey ?? url
    }
    
    private func showActivityLoading(view: UIView) {
        if activityLoading == nil {
            activityLoading = UIActivityIndicatorView(style: .gray)
            activityLoading!.backgroundColor = UIColor.clear
            activityLoading!.color = UIColor.white
            activityLoading!.startAnimating()
            activityLoading!.autoresizingMask.insert(.flexibleLeftMargin)
            activityLoading!.autoresizingMask.insert(.flexibleRightMargin)
            activityLoading!.autoresizingMask.insert(.flexibleTopMargin)
            activityLoading!.autoresizingMask.insert(.flexibleBottomMargin)
        }
        view.addSubview(activityLoading!)
        
        activityLoading!.center = CGPoint(x: view.frame.width/2, y: view.frame.height/2)
        
    }
    
    private func hiddenActivityLoading() {
        activityLoading?.stopAnimating()
        activityLoading?.removeFromSuperview()
        activityLoading = nil
    }
    
    //MARK: 退出时一定要销毁
    deinit {
        NotificationCenter.default.removeObserver(self)
        
        videoStatusTimer?.invalidate()
        videoStatusTimer = nil
    }
}

extension CustomAVPlayerView: PlayerDelegate, PlayerStatusDelegate {
    //MARK: - PlayerDelegate
    //MARK: - PlayerStatusDelegate
    func playerPlayStatus(player: CustomMediaPlayer, status: PlayStatus) {
        playStatus = status
//        centerPlayBtn.isSelected = !(status == .play)
        playButton.isSelected = !(status == .play)
        switch status {
        case .play:
            delegate?.playWithPlayer?(player: self)
        case .failed:
            hiddenActivityLoading()
            showBar()
            delegate?.playFailedWithPlayer?(player: self)
        case .finish:
            showBar()
            
            isPlayFinished = true
            delegate?.playFinished?(player: self)
        case .pause:
            showBar()
            delegate?.pauseWithPlayer?(player: self)
        case .cancel:
            hiddenActivityLoading()
            showBar()
            delegate?.playCancelWithPlayer?(player: self)
        case .failedToPause:
            reStart = true
        }
    }
    
    func playerPlayProgress(player: CustomMediaPlayer, currentTime: Double) {
        position = currentTime
        let minutesElapsed = floor(currentTime/60)
        let secondsElapsed = floor(fmod(currentTime, 60.0))
        currentTimeLabel.text = String(format: "%.0f:%02.0f", minutesElapsed, secondsElapsed)
        currentTimeLabel.sizeToFit()
        currentTimeLabel.frame.size.height = barHeight
        durationSlider.value = Float(currentTime)
        delegate?.playProgress?(player: self, currentTime: currentTime)
    }
    
    func playerReadyToPlay(player: CustomMediaPlayer, totalTime: Double) {
        hiddenActivityLoading()
        timerHiddenBar()
//        centerPlayBtn.isHidden = false
        playButton.isHidden = false
        durationSlider.isUserInteractionEnabled = true
        durationSlider.minimumValue = 0
        durationSlider.maximumValue = Float(totalTime)
        let minutesRemaining = floor(totalTime / 60.0)
        let secondsRemaining = floor(fmod(totalTime, 60.0))
        videoTimeLabel.text = String(format: "%.0f:%02.0f", minutesRemaining, secondsRemaining)
        videoTimeLabel.sizeToFit()
        videoTimeLabel.frame.size.height = barHeight
    }
    
    func playerCacheProgress(player: CustomMediaPlayer, progress: Float) {
        durationSlider.cacheProgress = progress
    }
}
