//
//  CustomMediaPlayer.swift
//  Eceibs
//
//  Created by sword on 2019/4/12.
//  Copyright © 2019 sword. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

enum PlayStatus {
    //开始播放
    case play
    //暂停播放
    case pause
    //播放结束
    case finish
    //播放失败
    case failed
    //播放取消
    case cancel
    //暂停一段时间后，播放器被杀死
    case failedToPause
}

enum MediaType {
    //视频
    case video
    //音频
    case audio
}

@objc protocol PlayerDelegate: class {
    
    @objc optional func playerReadyToPlay(player: CustomMediaPlayer, totalTime: Double)
    
    @objc optional func playerCacheProgress(player: CustomMediaPlayer, progress: Float)
        
    func playerPlayProgress(player: CustomMediaPlayer, currentTime: Double)
}

///播放状态delegate
protocol PlayerStatusDelegate: class {
    func playerPlayStatus(player: CustomMediaPlayer, status: PlayStatus)
}

class CustomMediaPlayer: NSObject {
    var playerItem: AVPlayerItem?
    
    var player: AVPlayer?
    
    var playerController: AVPlayerViewController?
    
    weak var delegate: PlayerDelegate?
    
    weak var statusDelegate: PlayerStatusDelegate?
    
    var urlStr: String = ""
    
    var playRate: Float = 1.0 {
        didSet{
            if let _player = player {
                _player.rate = playRate
            }
        }
    }
    
    ///多媒体类型，默认为音频
    var mediaType: MediaType = .audio
    
    var playTimeObsever: Any?
    
    //MARK: - Init
    override init() {
        super.init()
        addNotification()
    }
    
    //设置播放的URL
    func playWithUrl(url: URL)  {
        urlStr = url.absoluteString
        removeObsever()
        
        let urlAsset = AVURLAsset(url: url)
        if mediaType == .audio {
            playAudio(asset: urlAsset)
        } else {
            playVideo(asset: urlAsset)
        }
    }
    
    //设置音频URL
    private func playAudio(asset: AVURLAsset) {
        playerItem = AVPlayerItem(asset: asset)
        
        if player == nil {
            player = AVPlayer(playerItem: playerItem)
            if #available(iOS 10.0, *) {
                ///ios10设为no后可边缓冲边播放
                player!.automaticallyWaitsToMinimizeStalling = false
            }
        } else {
            player!.replaceCurrentItem(with: playerItem)
        }
        addObsever()
        play()
    }
    
    //设置视频URL
    private func playVideo(asset: AVURLAsset) {
        playerItem = AVPlayerItem(asset: asset)
        
        if player == nil {
            player = AVPlayer(playerItem: playerItem)
            playerController = AVPlayerViewController()
        } else {
            player!.replaceCurrentItem(with: playerItem)
        }
        
//        if #available(iOS 10.0, *) {
//            //播放器是否应自动延迟播放以尽量减少停顿
//            player?.automaticallyWaitsToMinimizeStalling = false
//            //播放器在播放头之前缓冲媒体的持续时间，以防止播放中断。该属性定义了首选的前向缓冲区持续时间（秒）。如果设置为0，播放器将为大多数使用情况选择适当的缓冲级别。将此属性设置为较低值会增加播放停顿和重新缓冲的机会，而将其设置为较高值会增加对系统资源的需求
//            playerItem?.preferredForwardBufferDuration = TimeInterval(0)
//        }
        
        playerController!.player = player
        playerController!.view.translatesAutoresizingMaskIntoConstraints = true
        playerController!.showsPlaybackControls = false
        playerController!.videoGravity = .resizeAspect
        addObsever()
        play()
    }
    
    ///playercontroller添加到某个view上
    func playerAddToSuperView(view: UIView) {
        if mediaType == .audio || playerController == nil {
            return
        }
        playerController!.view.frame = view.bounds
        playerController!.view.autoresizingMask.insert(.flexibleHeight)
        playerController!.view.autoresizingMask.insert(.flexibleWidth)
        playerController!.view.isUserInteractionEnabled = false
        view.addSubview(playerController!.view)
    }
    
    //MARK: Obsever and notification
    //注册观察者
    private func addObsever() {
        guard let pItem = playerItem, let player = player else { return }
        pItem.addObserver(self, forKeyPath: "status", options: .new, context: nil)
        pItem.addObserver(self, forKeyPath: "loadedTimeRanges", options: .new, context: nil)
        player.addObserver(self, forKeyPath: "rate", options: .new, context: nil)
    }
    
    //移除观察者
    private func removeObsever() {
        if let pItem = playerItem, let player = player {
            pItem.removeObserver(self, forKeyPath: "status", context: nil)
            pItem.removeObserver(self, forKeyPath: "loadedTimeRanges", context: nil)
            player.removeObserver(self, forKeyPath: "rate", context: nil)
            if let obsever = playTimeObsever {
                player.removeTimeObserver(obsever)
                playTimeObsever = nil
            }
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        switch keyPath {
        case "status":
            if playerItem?.status == .readyToPlay {
//                play()
                videoPlayObsever()
                delegate?.playerReadyToPlay?(player: self, totalTime: getTotalTime())
                return
            }
            if playerItem?.status == .failed {
                statusDelegate?.playerPlayStatus(player: self, status: .failed)
            }
            return
        case "loadedTimeRanges":
            let progress = getCacheProgress()
            delegate?.playerCacheProgress?(player: self, progress: progress)
            return
        case "rate":
            let status = getPlayStatus()
            statusDelegate?.playerPlayStatus(player: self, status: status)
            return
        default:
            break
        }
    }
    
    ///获取缓冲进度
    private func getCacheProgress() -> Float {
        guard let _ = playerItem else {
            return 0
        }
        let loadedTimeRange = playerItem?.loadedTimeRanges
        let timeRange = loadedTimeRange?.first?.timeRangeValue //缓冲区域
        if timeRange == nil {
            return 0
        }
        let startSeconds: Double? = timeRange?.start.seconds  //开始缓冲的点
        let durationSeconds: Double? = timeRange?.duration.seconds //此次缓冲的时间
        let timeInterval: Double? = Double(startSeconds!) + Double(durationSeconds!)
        let videoDuration = playerItem?.asset.duration
        let totalDuration = videoDuration?.seconds
        let progress = Float(timeInterval! / totalDuration!)
        return progress
    }
    
    ///获取播放状态
    private func getPlayStatus() -> PlayStatus {
        var status: PlayStatus

        if player?.rate == 0 {
            status = .pause
        } else {
            status = .play
        }
        return status
    }
    
    ///监听播放进度
    private func videoPlayObsever() {
        playTimeObsever = player?.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 30), queue: .main, using: { [weak self] (time: CMTime) in
            guard let this = self else { return }
            
            var currentPlayTime = TimeInterval(time.value) / TimeInterval(time.timescale)
            
            let totalTime = this.getTotalTime()
            
            if currentPlayTime > totalTime {
                currentPlayTime = totalTime
            }
            
            this.delegate?.playerPlayProgress(player: this, currentTime: currentPlayTime)
        })
    }
    
    private func addNotification() {
        //播放完成通知
        NotificationCenter.default.addObserver(self, selector: #selector(playFinished), name: .AVPlayerItemDidPlayToEndTime, object: playerItem)
        
        NotificationCenter.default.addObserver(self, selector: #selector(failedToPlayToEndTime), name: .AVPlayerItemFailedToPlayToEndTime, object: playerItem)
        
        NotificationCenter.default.addObserver(self, selector: #selector(failedToPlayToEndTime), name: .AVPlayerItemPlaybackStalled, object: playerItem)
                
        NotificationCenter.default.addObserver(self, selector: #selector(failedToPlayToEndTime), name: .AVPlayerItemNewErrorLogEntry, object: playerItem)
        
        //停止所有多媒体播放
        NotificationCenter.default.addObserver(self, selector: #selector(stop), name: NSNotification.Name(rawValue: stopAllMediaPlay), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(pause), name: NSNotification.Name(rawValue: pauseAllMediaPlay), object: nil)
    }
    
    ///播放完成
    @objc private func playFinished(noti: Notification) {
        let currentPlayerItem = noti.object as? AVPlayerItem
        if currentPlayerItem == playerItem {
            statusDelegate?.playerPlayStatus(player: self, status: .finish)
        }
    }
    
    @objc private func failedToPlayToEndTime() {
        ///未缓冲完暂停一段时间后，系统会自动杀死播放器，会调用此方法
        printLog("failedToPlayToEndTime")
        statusDelegate?.playerPlayStatus(player: self, status: .failedToPause)
    }
    
    ///获取总时长
    func getTotalTime() -> Double {
        guard let pItem = playerItem else {
            return 0
        }
        return TimeInterval(pItem.asset.duration.value) / TimeInterval(pItem.asset.duration.timescale)
    }
    
    ///获取当前播放时间
    func getCurrentTime() -> Double{
        guard let pItem = playerItem else {
            return 0
        }
       return TimeInterval(pItem.currentTime().value) / TimeInterval(pItem.currentTime().timescale)
    }
    
    @objc func pause() {
        player?.pause()
    }
    
    @objc func stop() {
        guard let _player = player else {
            return
        }
        _player.pause()
        _player.replaceCurrentItem(with: nil)
        _player.cancelPendingPrerolls()
        removeObsever()
        //player = nil
        if playerItem != nil {
            playerItem = nil
        }
//        if playerController != nil {
//            playerController = nil
//        }
        statusDelegate?.playerPlayStatus(player: self, status: .cancel)
    }
    
    func play() {
        guard let _ = player else { return }
        
        player?.play()
    }
    
    ///从头重新播放
    func replay() {
        guard let pItem = playerItem else { return }
        
        let firstTime = CMTimeMakeWithSeconds(0, preferredTimescale: pItem.currentTime().timescale)
        pItem.seek(to: firstTime, toleranceBefore: .zero, toleranceAfter: .zero)
        play()
    }
    
    //seek到某个时间点
    func playerSeekTo(time: Float, finish:@escaping() ->()) {
        guard let pItem = playerItem else {
            return
        }
        let changeTime = CMTimeMakeWithSeconds(Float64(time),  preferredTimescale: pItem.currentTime().timescale)
        pItem.seek(to: changeTime, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] finished in
            guard let _ = self else { return }
            finish()
        }
    }
    
    ///获取系统音量
    func audioVolume() -> Float {
        let audioSession = AVAudioSession.sharedInstance()
        return audioSession.outputVolume
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        removeObsever()
    }
}
