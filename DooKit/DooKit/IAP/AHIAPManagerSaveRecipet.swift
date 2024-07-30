//
//  AHIAPManagerSaveRecipet.swift
//  DooKit
//
//  Created by Alibaba on 2024/7/29.
//

import Foundation

class AHIAPManagerSaveRecipet {
    
    fileprivate static let AHLOCALRECIPETKEY = "AHLOCALRECIPETKEY"
    
    /// 存储当前订单票据
    /// - Parameter receiptData: 票据信息
    /// - Parameter orderId: 当前订单id，由ProductId + OrderId  组成
    ///
    class func ah_saveVerifyRecipetData(_ receiptData: Data, _ orderId: String, _ userId: String) {
        var localRecipetDict = [String: [String: Data]]()
        if let savedDict = ah_readRecipetData() {
            localRecipetDict.merge(savedDict) { (current, _) in current }
        }
        var orderDic = [String: Data]()
        orderDic[orderId] = receiptData
        // 找到userId是否存在其他订单，存在则进行追加
        if let userRecipetDic = localRecipetDict[userId] {
            orderDic.merge(userRecipetDic) { (current, _) in current }
        }
        localRecipetDict[userId] = orderDic
        AHIAPManagerKeyChain.save(key: AHLOCALRECIPETKEY, value: localRecipetDict)
    }
    
    /// 清除订单票据
    /// - Parameter orderId: 订单 id
    class func ah_clearnOrderRecipetData(_ orderId: String){
        if let savedDict = ah_readRecipetData() {
            var muDict = savedDict
            for (key, valueDict) in savedDict {
                var dict = valueDict
                dict[orderId] = nil
                muDict[key] = dict
            }
            AHIAPManagerKeyChain.save(key: AHLOCALRECIPETKEY, value: muDict)
        }
    }
    
    /// 读取用户本地存储的未完成的订单和票据列表
    /// - Parameter userId: 用户id
    /// - Returns [String: Any]:  未完成的订单列表 [orderId: recipet]
    class func ah_getUserRecipetList(_ userId: String) -> [String: Data]? {
        if let savedDict = ah_readRecipetData(),
           let userRecipetDic = savedDict[userId]{
            return userRecipetDic
        }
        return nil
    }
    
    
    /// 根据订单查询票据
    /// - Parameter orderId: 订单id
    /// - Returns String :  未完成的订单票据
    class func ah_getOrderRecipetList(_ orderId: String) -> Data? {
        if let savedDict = ah_readRecipetData() {
            // 获取所有值
            let valuesArray = Array(savedDict.values)
            for orderDict in valuesArray {
                if let recipet = orderDict[orderId]  {
                    return recipet
                }
                break
            }
        }
        return nil
    }
    
    /// 读取本地存储的票据和订单信息
    /// - Returns [String: [String: Any]]: 用户Id作为key，区分不同用户，避免A 用户的权益 恢复或者下发到 B 用户 [userId: [oriderId: recipted]], 一个用户可能对应多笔订单，一笔订单对应一个票据
    fileprivate class func ah_readRecipetData() -> [String: [String: Data]]? {
        let localRecipetDict = AHIAPManagerKeyChain.get(key: AHLOCALRECIPETKEY) as? [String: [String: Data]]
        return localRecipetDict
    }
    
}
