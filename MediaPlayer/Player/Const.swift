//
//  Const.swift
//  MediaPlayer
//
//  Created by sword on 2021/2/18.
//

import Foundation
import UIKit

//打印，debug模式打印，release模式不处理
func printLog(_ item: Any...) {
    #if DEBUG
        for obj: Any in item {
            print(obj)
        }
    #endif
}

///获取window安全区
var screenSafeAreaInset: UIEdgeInsets{
    if #available(iOS 11.0, *){
        if let window = UIApplication.shared.windows.first {
            return window.safeAreaInsets
        }
    }
    return UIEdgeInsets.zero
}


///window宽度
var screenWidth: CGFloat{
    return UIScreen.main.bounds.width
}

///window高度
var screenHeight: CGFloat{
    return UIScreen.main.bounds.size.height
}


//停止播放多媒体
let stopAllMediaPlay = "stopAllMediaPlay"

//暂停播放多媒体
let pauseAllMediaPlay = "pauseAllMediaPlay"

//音频播放通知
let audioPlayNotification = "audioPlayNotification"

//音频暂停通知
let audioPauseNotification = "audioPauseNotification"

typealias VoidVoidBlock = () -> ()

typealias BoolVoidBlock = (Bool) -> ()
