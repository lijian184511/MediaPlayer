//
//  AudioSlider.swift
//  Eceibs
//
//  Created by sword on 2018/3/27.
//  Copyright © 2018年 sword. All rights reserved.
//

import UIKit

private let audioSliderThumbBoundX:CGFloat = 10
private let audioSliderThumbBoundY:CGFloat = 10

class AudioSlider: UISlider {
    
    var sliderType: SliderType = .audio
    
    var thumbStyle: ThumbStyle = .round
    
    var lastBounds:CGRect? = nil  //进度条bounds
    
    var touchCancel: VoidVoidBlock?
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
        if self.sliderType == SliderType.audio {
            self.settingTrackImage()
        }else{
            self.videoSetTrack()
        }
    }
    
    func settingTrackImage() {
        self.minimumTrackTintColor = UIColor.subjectColor()
        self.maximumTrackTintColor = UIColor.clear
        setThumb()
    }
    
    private func videoSetTrack() {
        self.setMinimumTrackImage(UIImage.init(named: "learn_video_slider"), for: .normal)
        self.setMaximumTrackImage(AudioSlider.imageWithColor(color: UIColor.clear,size: CGSize.init(width: 4.0, height: 5)), for: .normal)
        //self.maximumTrackTintColor = UIColor.clear
        setThumbImage(UIImage.init(named: "learn_video_thumb"), for: .normal)
        setThumbImage(UIImage.init(named: "learn_video_thumb"), for: .highlighted)
    }
    
    private func setThumb() {
        if thumbStyle == .square {
            setThumbImage(AudioSlider.imageWithColor(color: UIColor.subjectColor(),size: CGSize.init(width: 4.0, height: 10.0)), for: .normal)
        }else{
            setThumbImage(AudioSlider.circleImage(radius: 5, color: UIColor.subjectColor()), for: .normal)
        }
    }
    
    override func thumbRect(forBounds bounds: CGRect, trackRect rect: CGRect, value: Float) -> CGRect {
        let result = super.thumbRect(forBounds: bounds, trackRect: rect, value: value)
        
        lastBounds = result
        return result
    }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let result = super.hitTest(point, with: event)
        if (point.y >= -audioSliderThumbBoundY) && (point.y < (lastBounds?.size.height)! + audioSliderThumbBoundY)  {
            var value:Float = 0
            value = Float(point.x - self.bounds.origin.x)
            value = value/Float(self.bounds.size.width)
            value = value<0 ? 0 : value
            value = value>1 ? 1: value
            
            value = value * (self.maximumValue - self.minimumValue) + self.minimumValue
            self.setValue(value, animated: true)
        }
        return result
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        var result  = super.point(inside: point, with: event)
        if result == false && point.y > -10 {
            if (point.x >= (lastBounds?.origin.x)! - audioSliderThumbBoundX) && (point.x <= (lastBounds?.origin.x)! + (lastBounds?.size.width)! + audioSliderThumbBoundX) && (point.y < (lastBounds?.size.height)! + audioSliderThumbBoundX) {
                result = true
            }
        }
        return result
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        ///结束滑动
        touchCancel?()
    }
    
    
    //MARK: - 工具方法
    class func imageWithColor(color:UIColor,size: CGSize) -> UIImage{
        let rect = CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height)
        UIGraphicsBeginImageContext(rect.size)
        let context:CGContext = UIGraphicsGetCurrentContext()!
        context.setFillColor(color.cgColor)
        context.fill(rect)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image!
    }
    
    class func circleImage(radius: CGFloat, color: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(CGSize.init(width: radius*2, height: radius*2), false, UIScreen.main.scale)
        let ctx = UIGraphicsGetCurrentContext()
        ctx?.setFillColor(color.cgColor)
        ctx?.addArc(center: CGPoint.init(x: radius, y: radius), radius: radius, startAngle: 0, endAngle: 2 * CGFloat(Double.pi), clockwise: false)
        
        ctx?.fillPath()
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
}
