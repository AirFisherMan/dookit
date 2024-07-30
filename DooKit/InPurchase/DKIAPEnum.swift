//
//  DKIAPEnum.swift
//  DooKit
//
//  Created by Alibaba on 2024/7/23.
//

import Foundation

/// Subscription Cycle
enum DKIAPEnumSubscriptionCycle {
    case week       // 周
    case month      // 月
    case quarter    // 季度
    case halfYear   // 半年
    case year       // 年
    
    var name: String {
        switch self {
        case .week: return "周"
        case .month: return "月"
        case .quarter: return "季度"
        case .halfYear: return "半年"
        case .year:return "年"
        }
    }
}

enum DKIAPEnumProductType: Equatable {
    case consumption    // 消耗品
    case parmanent      // 永久购买
    case subscribe(cycle: DKIAPEnumSubscriptionCycle) // 订阅
    case nonRenewed     // 非连续性续费，单次购买
}

enum DKIAPEnumVerifyReceiptURLType: String {
    case server = "http://remind.jrysdq.cn:8150/verify"
    case production = "https://buy.itunes.apple.com/verifyReceipt"
    case sanbox = "https://sandbox.itunes.apple.com/verifyReceipt"
}

