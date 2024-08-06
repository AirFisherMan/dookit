//
//  ACAudioRecorderToolDelegate.swift
//  DooKit
//
//  Created by Alibaba on 2024/7/30.
//

import UIKit

protocol ACAudioRecorderToolDelegate: AnyObject {
    
    func ac_beginRecord()
    
    func ac_stopRecord()
    
    func ac_puaseRecord()
    
    func ac_reRecord()
    
    func ac_recordIngDuration(_ duration: Int)
    
    func ac_recordFailure(_ reson: String)
}

extension ACAudioRecorderToolDelegate {
    
    func ac_beginRecord() {}
    
    func ac_stopRecord() {}
    
    func ac_puaseRecord() {}
    
    func ac_reRecord() {}
    
    func ac_recordIngDuration(_ duration: Int) {}
    
    func ac_recordFailure(_ reson: String) {}
}
