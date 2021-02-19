//
//  AudioView.swift
//  Eceibs
//
//  Created by sword on 2019/4/15.
//  Copyright © 2019 sword. All rights reserved.
//

import UIKit

fileprivate let playBtnWidth: CGFloat = 28.0

fileprivate let timeColor = UIColor.init(r: 169, g: 174, b: 175)

protocol AudioPlayerViewDelegate: class {
    func audioPlayTap(audioView: AudioPlayerView)
    
    func audioPlayStatus(audioView: AudioPlayerView, status: PlayStatus)
}

class AudioPlayerView: UIView, PlayerDelegate, PlayerStatusDelegate {

    var loadFailed: VoidVoidBlock?
    
    lazy private var audioImg = UIImageView()
    
    lazy private var audioLabel = UILabel()
    
    lazy private var playButton = UIButton(type: .custom)
    
    lazy var playTimeLabel = UILabel()
    
    lazy var totalTimeLabel =  UILabel()
    
    ///进度条
    lazy var durationSlider = AudioSliderView.init()
    
    private var player: CustomMediaPlayer?
    
    private var isPlay: Bool = false
    
    ///音频url
    var url: String?
    
    weak var delegate: AudioPlayerViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        drawView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        drawView()
    }
    
    ///画控件
    private func drawView() {
        audioImg.frame = CGRect(x: 10, y: (frame.height - 11)/2, width: 12, height: 11)
        audioImg.image = UIImage(named: "video_volume")
        addSubview(audioImg)
        
        audioLabel.text = "音频"
        audioLabel.font = UIFont.systemFont(ofSize: 11)
        audioLabel.sizeToFit()
        audioLabel.frame = CGRect(x: audioImg.frame.maxX + 5, y: (frame.height - audioLabel.frame.height)/2, width: audioLabel.frame.width, height: audioLabel.frame.height)
        addSubview(audioLabel)
        
        playButton.setImage(UIImage(named: "column_audio_play"), for: .normal)
        playButton.setImage(UIImage(named: "column_audio_pause"), for: .selected)
        playButton.frame = CGRect(x: audioLabel.frame.maxX + 10, y: (frame.height - playBtnWidth)/2, width: playBtnWidth, height: playBtnWidth)
        playButton.addTarget(self, action: #selector(playOrPause), for: .touchUpInside)
        addSubview(playButton)
        
        playTimeLabel.text = "00:00"
        playTimeLabel.frame = CGRect(x: playButton.frame.maxX + 5, y: (frame.height - 12)/2, width: 30, height: 12)
        playTimeLabel.textColor = timeColor
        playTimeLabel.font = UIFont.systemFont(ofSize: 9)
        playTimeLabel.textAlignment = .right
        addSubview(playTimeLabel)
        
        addSlider()
        
        totalTimeLabel.text = "00:00"
        totalTimeLabel.frame = CGRect(x: durationSlider.frame.maxX + 5, y: playTimeLabel.frame.minY, width: playTimeLabel.frame.width, height: playTimeLabel.frame.height)
        totalTimeLabel.textColor = timeColor
        totalTimeLabel.font = UIFont.systemFont(ofSize: 9)
        totalTimeLabel.textAlignment = .left
        totalTimeLabel.isHidden = true
        addSubview(totalTimeLabel)
        self.backgroundColor = UIColor.white
        layer.cornerRadius = 4
        layer.masksToBounds = true
    }
    
    private func addSlider() {
        durationSlider.value = 0
        durationSlider.sliderType = SliderType.audio
        durationSlider.thumbStyle = .round
        durationSlider.slider.isContinuous = true
        durationSlider.slider.isUserInteractionEnabled = false
        durationSlider.slider.addTarget(self, action: #selector(sliderValueChange(slider:)), for: .valueChanged)
        let durationSliderX: CGFloat = playTimeLabel.frame.maxX + 5
        durationSlider.frame = CGRect.init(x: durationSliderX, y: (frame.height - 11)/2, width: frame.width - 40 - durationSliderX , height: 11)
        durationSlider.autoresizingMask.insert(.flexibleWidth)
        durationSlider.autoresizingMask.insert(.flexibleHeight)
        durationSlider.backgroundColor = UIColor.white
        self.addSubview(durationSlider)
    }
    
    private func playWithUrl(url: String) {
        guard let playUrl = URL(string: url) else {
            return
        }
        if player == nil {
            player = CustomMediaPlayer()
            player!.mediaType = .audio
            player!.delegate = self
            player!.statusDelegate = self
            player!.playWithUrl(url: playUrl)
        }else{
            player!.play()
        }
    }
    
    func stop() {
        guard let _player = player else {
            return
        }
        _player.stop()
    }
    
    func pause() {
        guard let _player = player else {
            return
        }
        _player.pause()
    }
    
    @objc private func playOrPause() {
        if url == nil {
            loadFailed?()
            return
        }
        if player == nil {
            delegate?.audioPlayTap(audioView: self)
            playWithUrl(url: url!)
            isPlay = true
            return
        }
        if isPlay == true {
            player!.pause()
            return
        }
        isPlay = true
        delegate?.audioPlayTap(audioView: self)
        player!.play()
    }
    
    //MARK: - PlayerDelegate
    //MARK: - PlayerStatusDelegate
    func playerPlayStatus(player: CustomMediaPlayer, status: PlayStatus) {
        switch status {
        case .play:
            isPlay = true
            playButton.isSelected = true
        case .failed, .finish, .pause, .cancel:
            if status == .finish {
                player.playerSeekTo(time: 0.0, finish: {()in })
                durationSlider.value = 0
            }else if status == .cancel {
                self.player = nil
            }
            isPlay = false
            playButton.isSelected = false
        default:
            break
        }
        delegate?.audioPlayStatus(audioView: self, status: status)
    }
    
    func playerPlayProgress(player: CustomMediaPlayer, currentTime: Double) {
        let floatCurrentTime = Float(currentTime)
        let minutes = floor(floatCurrentTime/60)
        let seconds = floor(fmod(floatCurrentTime, 60.0))
        playTimeLabel.text = String.init(format: "%.0f:%02.0f", minutes,seconds)
        durationSlider.value = floatCurrentTime
    }
    
    func playerCacheProgress(player: CustomMediaPlayer, progress: Float) {
        durationSlider.cacheProgress = progress
    }
    
    @objc func sliderValueChange(slider:UISlider) {
        if player == nil {
            return
        }
        player!.playerSeekTo(time: slider.value, finish:{()in
        })
    }
    
    func playerReadyToPlay(player: CustomMediaPlayer, totalTime: Double){
        let minutes = floor(totalTime / 60.0)
        let seconds = floor(fmod(totalTime, 60.0))
        totalTimeLabel.isHidden = false
        totalTimeLabel.text = String(format: "%.0f:%02.0f", minutes,seconds)
        durationSlider.maximumValue = Float(totalTime)
        durationSlider.slider.isUserInteractionEnabled = true
    }
    
}
