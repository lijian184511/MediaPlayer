//
//  ViewController.swift
//  MediaPlayer
//
//  Created by sword on 2021/2/18.
//

import UIKit

class ViewController: UIViewController {

    private var playerView: CustomAVPlayerView?
    
    private var audioView: AudioPlayerView?
    
    let videoUrl = "https://vd4.bdstatic.com/mda-mbhj0ge1hwx4nwzm/sc/cae_h264_clips/1613626258/mda-mbhj0ge1hwx4nwzm.mp4?auth_key=1613638179-0-0-40bf74df30acb8613cd81b5f4dbbdc39&bcevod_channel=searchbox_feed&pd=1&pt=3&abtest=8_2"
    
    let audioUrl = "https://aod.cos.tx.xmcdn.com/group30/M02/3F/2A/wKgJXlmBkw2zg0LjAKntzSZLubI803.m4a"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addPlayer()
        
        addAudioPlayer()
    }

    ///视频播放器
    private func addPlayer() {
        if playerView == nil {
            playerView = CustomAVPlayerView(frame: CGRect(x: 0, y: 100, width: view.frame.width, height: 200))
            playerView!.delegate = self
            playerView!.hiddenTopBar = true
            playerView!.allowFullScreen = true
            if let url = URL(string: videoUrl) {
                playerView!.playWithUrl(videoUrl: url)
            }
            
            playerView!.showPlayRate = false
            view.addSubview(playerView!)
        }
    }
    
    ///音频播放器
    private func addAudioPlayer() {
        if audioView == nil {
            audioView = AudioPlayerView(frame: CGRect(x: 10, y: 350, width: view.frame.width - 20, height: 43))
            audioView!.url = audioUrl
            audioView!.delegate = self
            view.addSubview(audioView!)
        }
    }
    
}

extension ViewController : CustomPlayerViewDelegate {
    
    func playWithPlayer(player: CustomAVPlayerView) {
        audioView?.pause()
    }
    
    func fullScreen(player:CustomAVPlayerView,fullScreen:Bool) {
        player.showPlayRate = fullScreen
        player.showPlayQuality = fullScreen
    }
}

extension ViewController : AudioPlayerViewDelegate {
    func audioPlayTap(audioView: AudioPlayerView) {
        
    }
    
    func audioPlayStatus(audioView: AudioPlayerView, status: PlayStatus) {
        if status == .play {
            playerView?.pause()
        }
    }
}
