//
//  AudioSliderView.swift
//  Eceibs
//
//  Created by sword on 2018/3/27.
//  Copyright © 2018年 sword. All rights reserved.
//

import UIKit

enum SliderType {
    case audio
    case video
}

enum ThumbStyle {
    ///方形
    case square
    ///圆形
    case round
}

class AudioSliderView: UIView {
    
    let cacheProgressView = UIProgressView.init()
    
    var sliderType: SliderType = .audio
    
    var thumbStyle: ThumbStyle = .round
    
    let slider = AudioSlider.init()
    
    private var _minimumValue: Float = 0
    var minimumValue: Float{
        get{
            return _minimumValue
        }
        set{
            _minimumValue = newValue
            self.slider.minimumValue = _minimumValue
        }
    }
    
    private var _maximumValue: Float = 0
    var maximumValue: Float{
        get{
            return _maximumValue
        }
        set{
            _maximumValue = newValue
            self.slider.maximumValue = _maximumValue
        }
    }
    
    private var _value: Float? = 0
    var value: Float?{
        get{
            return _value
        }
        set{
            _value = newValue
            self.slider.value = _value!
        }
    }
    
    
    //缓冲进度
    private var _cacheProgress:Float = 0
    
    var cacheProgress:Float{
        set{
            _cacheProgress = newValue
            self.cacheProgressView.setProgress(Float(newValue), animated: false)
        }
        get{
            return _cacheProgress
        }
    }
    
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
        self.backgroundColor = UIColor.clear
        
        if self.sliderType == SliderType.audio {
            self.addAudioProgressView()
        }else{
            self.addVideoProgressView()
        }
        self.addSlider()
    }
    
    private func addAudioProgressView() {
        cacheProgressView.frame = CGRect.init(x: 5, y: 0, width: self.frame.size.width - 5, height: 3)
        cacheProgressView.trackTintColor = UIColor.color238()
        cacheProgressView.progressTintColor = UIColor.sliderProgressColor()
        cacheProgressView.isUserInteractionEnabled = false
        cacheProgressView.autoresizingMask.insert(.flexibleWidth)
        cacheProgressView.autoresizingMask.insert(.flexibleHeight)
        self.addSubview(cacheProgressView)
        cacheProgressView.center = CGPoint.init(x: self.frame.size.width/2, y: self.frame.size.height/2)
    }
    
    private func addVideoProgressView() {
        cacheProgressView.frame = CGRect.init(x: 5, y: 0, width: self.frame.size.width - 4, height: self.frame.size.height-1)
        cacheProgressView.trackImage = UIImage.init(named: "learn_video_sliderBg")
        if #available(iOS 14.0, *) {
            cacheProgressView.transform = CGAffineTransform.init(scaleX: 1.0, y: 1.0)
        }else{
            cacheProgressView.transform = CGAffineTransform.init(scaleX: 1.0, y: 2.0)
        }
        
        cacheProgressView.progressTintColor = UIColor.color160()
        cacheProgressView.isUserInteractionEnabled = false
        cacheProgressView.autoresizingMask.insert(.flexibleWidth)
        cacheProgressView.autoresizingMask.insert(.flexibleHeight)

        self.addSubview(cacheProgressView)
        cacheProgressView.center = CGPoint.init(x: self.frame.size.width/2, y: self.frame.size.height/2)
    }

    private func addSlider() {
        slider.frame = CGRect.init(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height)
        slider.sliderType = self.sliderType
        slider.thumbStyle = thumbStyle
        slider.autoresizingMask.insert(.flexibleWidth)
        slider.autoresizingMask.insert(.flexibleHeight)
        addSubview(slider)
        //减去0.5是因为 slider与progressview frame不会完全重合，正好差0.5个像素点
        slider.center = CGPoint.init(x: cacheProgressView.center.x, y: (cacheProgressView.center.y - 0.5))
    }
    
}
