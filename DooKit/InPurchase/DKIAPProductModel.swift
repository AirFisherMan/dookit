//
//  DKIAPProductModel.swift
//  DooKit
//
//  Created by Alibaba on 2024/7/23.
//

import Foundation
import StoreKit

public class DKIAPProductModel {
    
    var pid: String = ""        // 商品id
    var name: String = ""       // 商品名
    var quanlity: Int = 1       // 数量
    var price: Float = 0.0      // 价格
    var originPrice: Float = 0.0// 原价
    var type: DKIAPEnumProductType = .consumption // 商品类型
    var product: SKProduct?     // 当前产品
    
    convenience init(pid: String, name: String, quanlity: Int = 1, price: Float, originPrice: Float = 0.0, type: DKIAPEnumProductType) {
        self.init()
        self.pid = pid
        self.name = name
        self.quanlity = quanlity
        self.price = price
        self.originPrice = originPrice
        self.type = type
        self.product = product
    }
    
    /// 试用天数
    var tryDay: Int {
        guard let product = self.product else { return 0 }
        // 限免期限
        if #available(iOS 11.2, *) {
            if let period = product.introductoryPrice?.subscriptionPeriod {
                if period.unit == .day {
                    return period.numberOfUnits
                } else if period.unit == .week {
                    return period.numberOfUnits * 7
                }
            }
        }
        return 0
    }
    
    /// 获取折扣
    var discount: Int {
        guard let discount = self.product?.introductoryPrice else { return 0 }
        switch discount.paymentMode {
        case .payAsYouGo:
            return 1
        case .payUpFront:
            return 1
        case .freeTrial:
            return 1
        default:
            break
        }
        return 0
    }
}
