//
//  ViewController.swift
//  DooKit
//
//  Created by Alibaba on 2024/7/23.
//

import UIKit

class ViewController: UIViewController {

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
        
        var dict = AHIAPManagerSaveRecipet.ah_getUserRecipetList("Cingjin")
        print(dict)
        
        var recipet = AHIAPManagerSaveRecipet.ah_getOrderRecipetList("230984029349")
        print(recipet)
        
        AHIAPManagerSaveRecipet.ah_clearnOrderRecipetData("1722244350948.563")
        
    }
}

