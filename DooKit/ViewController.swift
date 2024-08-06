//
//  ViewController.swift
//  DooKit
//
//  Created by Alibaba on 2024/7/23.
//

import UIKit

class ViewController: UIViewController, ACAudioRecorderToolDelegate {
    
    func ac_beginRecord() {
        print("begin")
    }
    
    func ac_stopRecord() {
        print("stop")
    }
    
    func ac_puaseRecord() {
        print("puase")
    }
    
    func ac_reRecord() {
        print("resum")
    }
    
    func ac_recordIngDuration(_ duration: Int) {
        print(duration)
    }
    
    func ac_recordFailure(_ reson: String) {
        print(reson)
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        AHIAPManager.shared.ah_fetchReceipt(forceRefresh: true)
//        self.title = "A"
        
        var emptyDict: [String: Int] = [:]
        emptyDict["a"] = 1
        print(emptyDict)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
//        AHIAPManagerSaveRecipet.ah_saveVerifyRecipetData(String(Date().timeIntervalSince1970 * 1000), String(Date().timeIntervalSince1970 * 1000), "Cingjin")
        
//        var dict = AHIAPManagerSaveRecipet.ah_getUserRecipetList("Cingjin")
//        print(dict)
//        
//        var recipet = AHIAPManagerSaveRecipet.ah_getOrderRecipetList("230984029349")
//        print(recipet)
//        
//        AHIAPManagerSaveRecipet.ah_clearnOrderRecipetData("1722244350948.563")
        

        
//        ACAudioRecorderTool.ac_config(["ICngjin": 1231792]).ac_beginRecording()
//        ACAudioRecorderTool.ac_config().ac_stopRecord()
        
        let audioRecorderTool = ACAudioRecorderTool.ac_config()
        audioRecorderTool.delegate = self
        audioRecorderTool.ac_beginRecording()
//        audioRecorderTool.ac_stopRecord()
        
    }
}

