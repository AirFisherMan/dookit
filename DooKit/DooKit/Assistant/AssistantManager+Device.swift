//
//  AssistantManager+Device.swift
//  DooKit
//
//  Created by Alibaba on 2024/7/26.
//

import Foundation
import UIKit

extension UIDevice {
    
    var att_getDeviceType: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        
        var size: Int = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        let platform = String(cString: model)
        
        switch platform {
            // iPhone
        case "iPhone1,1": return "iPhone 2G"
        case "iPhone1,2": return "iPhone 3G"
        case "iPhone2,1": return "iPhone 3GS"
        case "iPhone3,1", "iPhone3,2", "iPhone3,3": return "iPhone 4"
        case "iPhone4,1": return "iPhone 4S"
        case "iPhone5,1", "iPhone5,2": return "iPhone 5"
        case "iPhone5,3", "iPhone5,4": return "iPhone 5c"
        case "iPhone6,1", "iPhone6,2": return "iPhone 5s"
        case "iPhone7,1": return "iPhone 6 Plus"
        case "iPhone7,2": return "iPhone 6"
        case "iPhone8,1": return "iPhone 6s"
        case "iPhone8,2": return "iPhone 6s Plus"
        case "iPhone8,4": return "iPhone SE"
        case "iPhone9,1": return "iPhone 7"
        case "iPhone9,2": return "iPhone 7 Plus"
        case "iPhone10,1", "iPhone10,4": return "iPhone 8"
        case "iPhone10,2", "iPhone10,5": return "iPhone 8 Plus"
        case "iPhone10,3", "iPhone10,6": return "iPhone X"
        case "iPhone11,8": return "iPhone XR"
        case "iPhone11,2": return "iPhone XS"
        case "iPhone11,6", "iPhone11,4": return "iPhone XS Max"
        case "iPhone12,1": return "iPhone 11"
        case "iPhone12,3": return "iPhone 11 Pro"
        case "iPhone12,5": return "iPhone 11 Pro Max"
        case "iPhone12,8": return "iPhone SE (2nd generation)"
        case "iPhone13,1": return "iPhone 12 mini"
        case "iPhone13,2": return "iPhone 12"
        case "iPhone13,3": return "iPhone 12 Pro"
        case "iPhone13,4": return "iPhone 12 Pro Max"
        case "iPhone14,4": return "iPhone 13 mini"
        case "iPhone14,5": return "iPhone 13"
        case "iPhone14,2": return "iPhone 13 Pro"
        case "iPhone14,3": return "iPhone 13 Pro Max"
        case "iPhone14,6": return "iPhone SE (3rd generation)"
        case "iPhone14,7": return "iPhone 14"
        case "iPhone14,8": return "iPhone 14 Plus"
        case "iPhone15,2": return "iPhone 14 Pro"
        case "iPhone15,3": return "iPhone 14 Pro Max"
        case "iPhone15,4": return "iPhone 15"
        case "iPhone15,5": return "iPhone 15 Plus"
        case "iPhone16,1": return "iPhone 15 Pro"
        case "iPhone16,2": return "iPhone 15 Pro Max"
            
            // iPod Touch
        case "iPod1,1": return "iPod Touch 1"
        case "iPod2,1": return "iPod Touch 2"
        case "iPod3,1": return "iPod Touch 3"
        case "iPod4,1": return "iPod Touch 4"
        case "iPod5,1": return "iPod Touch 5"
        case "iPod7,1": return "iPod Touch 6"
        case "iPod9,1": return "iPod Touch 7"
            
            // iPad Mini
        case "iPad2,5", "iPad2,6", "iPad2,7": return "iPad Mini 1"
        case "iPad4,4", "iPad4,5", "iPad4,6": return "iPad Mini 2"
        case "iPad4,7", "iPad4,8", "iPad4,9": return "iPad Mini 3"
        case "iPad5,1", "iPad5,2": return "iPad Mini 4"
        case "iPad11,1", "iPad11,2": return "iPad Mini 5"
        case "iPad14,1", "iPad14,2": return "iPad Mini 6"
            
            // iPad Pro
        case "iPad6,3", "iPad6,4": return "iPad Pro 9.7"
        case "iPad6,7", "iPad6,8": return "iPad Pro 12.9"
        case "iPad7,1", "iPad7,2": return "iPad Pro 2 12.9"
        case "iPad7,3", "iPad7,4": return "iPad Pro 10.5"
        case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4": return "iPad Pro 11"
        case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8": return "iPad Pro 3 12.9"
        case "iPad8,10", "iPad8,11": return "iPad Pro 2 11"
        case "iPad13,4", "iPad13,5", "iPad13,6", "iPad13,7": return "iPad Pro 4 11"
        case "iPad13,8", "iPad13,9", "iPad13,10", "iPad13,11": return "iPad Pro 4 12.9"
            
            // iPad Air
        case "iPad4,1", "iPad4,2", "iPad4,3": return "iPad Air"
        case "iPad5,3", "iPad5,4": return "iPad Air 2"
        case "iPad11,3", "iPad11,4": return "iPad Air 3"
        case "iPad13,1", "iPad13,2", "iPad13,3": return "iPad Air 4"
        case "iPad13,16", "iPad13,17": return "iPad Air 5"
            
            // iPad
        case "iPad1,1": return "iPad 1"
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4": return "iPad 2"
        case "iPad3,1", "iPad3,2", "iPad3,3": return "iPad 3"
        case "iPad3,4", "iPad3,5", "iPad3,6": return "iPad 4"
        case "iPad6,11", "iPad6,12": return "iPad 5"
        case "iPad7,5", "iPad7,6": return "iPad 6"
        case "iPad7,11", "iPad7,12": return "iPad 7"
        case "iPad11,6", "iPad11,7": return "iPad 8"
        case "iPad12,1", "iPad12,2": return "iPad 9"
        case "iPad13,18", "iPad13,19": return "iPad 10"
            
            // Simulator
        case "i386", "x86_64": return "iPhone Simulator"
            
        default: return platform
        }
    }
}
