//
//  UIColor+Extension.swift
//  Eceibs
//
//  Created by sword on 2017/8/2.
//  Copyright © 2017年 sword. All rights reserved.
//

/**
 *  UIColor扩展类
 */


import Foundation
import UIKit

extension UIColor{
    
    convenience init(r : CGFloat, g : CGFloat, b : CGFloat, alpha : CGFloat = 1.0) {
        self.init(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: alpha)
    }
    
    //主题色（深蓝）
    class func subjectColor() -> UIColor {
        return UIColor.init(red: 0.0, green: 85/255.0, blue: 135/255.0, alpha: 1)
    }
    
    class func color238() -> UIColor {
        return UIColor.init(red: 238/255.0, green: 238/255.0, blue: 238/255.0, alpha: 1.0)
    }
    
    class func color160() -> UIColor {
        return UIColor.init(red: 160/255.0, green: 160/255.0, blue: 160/255.0, alpha: 1.0)
    }
    
    class func sliderProgressColor() -> UIColor {
        return UIColor.init(red: 192/255.0, green: 192/255.0, blue: 192/255.0, alpha: 1.0)
    }
    
}
