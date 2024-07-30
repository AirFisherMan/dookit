//
//  AssistantManager+String.swift
//  DooKit
//
//  Created by Alibaba on 2024/7/26.
//

import Foundation
import CommonCrypto

extension String {
    
    var att_integerValue: Int {
        return (self as NSString).integerValue
    }
    
    var att_md5String: String{
        
        let str = self.cString(using: String.Encoding.utf8)
        let strLen = CUnsignedInt(self.lengthOfBytes(using: String.Encoding.utf8))
        let digestLen = Int(CC_MD5_DIGEST_LENGTH)
        let result = UnsafeMutablePointer<CUnsignedChar>.allocate(capacity: digestLen)
        CC_MD5(str!, strLen, result)
        let hash = NSMutableString()
        for i in 0 ..< digestLen {
            hash.appendFormat("%02x", result[i])
        }
        result.deallocate()
        return String(format: hash as String)
    }
}
