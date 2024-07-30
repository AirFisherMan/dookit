//
//  DKIAPInPurchaseManager.swift
//  DooKit
//
//  Created by Alibaba on 2024/7/23.
//

import Foundation

#if canImport(StoreKit)
import StoreKit

#if canImport(SwiftyStoreKit)
import SwiftyStoreKit

class DKIAPInPurchaseManager: NSObject {
    
    let permanentKey = "com.aaaa.iii"
    let subscriptionKey = "com.bbbb.iii"
    let subscriptionExpiryDateKey = "com.cccc.iii"
    
    static let sharedInstance = DKIAPInPurchaseManager()
    // 处理回调
    // 是否响应应用商店点击订阅信息的回调
    var sholdAddStorePaymentHandler: ShouldAddStorePaymentHandler?
    // 共享密钥
    var shareSecret: String = ""
    // 默认商品列表
    var productList: [DKIAPProductModel] = []
    // 连续订阅
    var productList_subscription: [DKIAPProductModel] = [
        DKIAPProductModel(pid: "com.app.1", name: "周会员", price: 9.9, type: .subscribe(cycle: .week)),
        DKIAPProductModel(pid: "com.app.2", name: "月会员", price: 19.9, type: .subscribe(cycle: .month)),
        DKIAPProductModel(pid: "com.app.3", name: "季度会员", price: 29.9, type: .subscribe(cycle: .quarter)),
        DKIAPProductModel(pid: "com.app.4", name: "年度会员", price: 39.9, type: .subscribe(cycle: .year))
    ]
    // 永久购买
    var productList_permanent: [DKIAPProductModel] = [
        DKIAPProductModel(pid: "com.app.1", name: "周会员", price: 9.9, type: .parmanent)
    ]
    
    // 是否是 Vip
    var isVip: Bool {
#if DEBUG
        return true
#endif
        if dk_isPurchasePermanent { return true }
        if dk_isSubscription { return true }
        
        return false
    }
    
    override init() {
        super.init()
        
        productList = productList_permanent + productList_subscription
        dk_addListen()
    }
}

//MARK: - Add Listener
extension DKIAPInPurchaseManager {
    
    fileprivate func dk_addListen() {
        SwiftyStoreKit.completeTransactions(atomically: false) { purchases in
            purchases.forEach { purchase in
                switch purchase.transaction.transactionState {
                case .purchased,.restored:
                    let donwloads = purchase.transaction.downloads
                    if !donwloads.isEmpty {
                        SwiftyStoreKit.start(donwloads)
                    } else if purchase.needsFinishTransaction {
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
                    print("订阅回调监听, \(purchase.transaction.transactionState.debugDescription): \(purchase.productId)")
                case .failed, .purchasing, .deferred:
                    break
                @unknown default:
                    break
                }
            }
        }
        
        SwiftyStoreKit.updatedDownloadsHandler = { donwloads in
            let contentURLList = donwloads.compactMap{ $0.contentURL }
            if contentURLList.count == donwloads.count {
                SwiftyStoreKit.finishTransaction(donwloads[0].transaction)
            }
        }
        
        SwiftyStoreKit.shouldAddStorePaymentHandler = {[weak self](payment, product) in
            return self?.sholdAddStorePaymentHandler?(payment,product) ?? false
        }
    }
}

//MARK: - 刷新票据
extension DKIAPInPurchaseManager {
    
    func dk_fetchReceipt(forceRefresh: Bool = true) {
        SwiftyStoreKit.fetchReceipt(forceRefresh: forceRefresh) { (result) in
            switch result {
            case .success(let receiptData):
                print("刷新成功：\(receiptData)")
            case .error(let error):
                print("刷新失败：\(error)")
            }
        }
    }
}

//MARK: - 从苹果后台获取商品列表
extension DKIAPInPurchaseManager {
    
    func dk_getProductsInfo(productIds: Set<String>, completion: @escaping ([DKIAPProductModel]) ->Void) {
        SwiftyStoreKit.retrieveProductsInfo(productIds) { result in
            result.retrievedProducts.forEach { product in
#if DEBUG
                print("内购产品：\(product.localizedTitle), 价格：\(product.price)")
#endif
                if #available(iOS 12.2, *) {
                    if let discount = product.introductoryPrice {
                        switch discount.paymentMode {
                        case .payAsYouGo:
                            print("随用随附折扣：\(discount.subscriptionPeriod.numberOfUnits) \(discount.localizedPrice ?? ""),\(discount.price)")
                        case .payUpFront:
                            print("提前支付折扣：\(discount.numberOfPeriods) \(discount.localizedPrice ?? "")")
                        case .freeTrial:
                            let period = discount.subscriptionPeriod
                            print("免费试用折扣：\(discount.numberOfPeriods) \(period.numberOfUnits) \(period.unit == .day ? "天":"")")
                        @unknown default:
                            break
                        }
                    }
                }
            }
            result.retrievedProducts.forEach { product in
                for localProduct in self.productList {
                    if localProduct.pid == product.productIdentifier {
                        localProduct.product = product
                        break
                    }
                }
            }
            self.productList.removeAll { item in
                return item.product == nil
            }
            completion(self.productList)
        }
    }
}

// MARK: - 订阅(包月、包年)
extension DKIAPInPurchaseManager {
    
    func dk_buySubscription(_ product: DKIAPProductModel, _ tryAgin: Bool = true, completion: @escaping (Bool ,Bool) ->Void) {
        guard product.type != .consumption && product.type != .parmanent && product.type != .nonRenewed  else {
            completion(false,false)
            return
        }
        self.dk_purchaseProduct(product.pid, quantity: product.quanlity) { result in
            switch result {
            case .success(let purchase):
                print("订阅产品\(purchase.productId)，购买成功")
                let validator = DKAppleReceiptValidatorX()
                SwiftyStoreKit.verifyReceipt(using: validator) { verifyResult in
                    switch verifyResult {
                    case .success(let receipt):
                        let subScriptionResult = SwiftyStoreKit.verifySubscription(ofType: .autoRenewable, productId: product.pid, inReceipt: receipt)
                        switch subScriptionResult {
                        case .purchased(let expiryDate, let items):
                            if let item = items.first {
                                self.dk_setPurchaseSubscription(productId: item.productId, expiryDate: expiryDate)
                                completion(true, true)
                            }
                        case .expired(let expiryDate, let items):
                            let df = DateFormatter()
                            df.dateFormat = "yyyy-MM-dd HH:mm"
                            print("订阅已过期: \(product.pid), 过期时间 \(df.string(from: expiryDate)). 订阅项: \(items.count)\n")
                            self.dk_cleanPurchaseSubscription()
                            completion(true, false)
                        case .notPurchased:
                            self.dk_cleanPurchaseSubscription()
                            completion(true, false)
                        }
                    case .error(_):
                        completion(true, false)
                    }
                }
            case .deferred(let purchase):
                print("订阅产品\(purchase.productId)，购买成功")
            case .error(_):
                if tryAgin {
                    self.dk_buySubscription(product, false, completion: completion)
                } else {
                    completion(false,false)
                }
            }
        }
    }
    
    /// 设置是否订阅
    fileprivate func dk_setPurchaseSubscription(productId: String, expiryDate: Date? = nil) {
        DKIAPKeychain.save(key: self.subscriptionKey, value: productId)
        DKIAPKeychain.save(key: self.subscriptionExpiryDateKey, value: expiryDate as Any)
    }
    
    fileprivate func dk_getPurchaseProductId() -> String? {
        if let productId = DKIAPKeychain.get(key: subscriptionKey) as? String{
            return productId
        }
        return nil
    }
    /// 清除订阅保存信息
    fileprivate func dk_cleanPurchaseSubscription() {
        DKIAPKeychain.delete(key: self.subscriptionKey)
        DKIAPKeychain.delete(key: self.subscriptionExpiryDateKey)
    }
    /// 是否已经订阅
    fileprivate var dk_isSubscription: Bool {
        let subscriptionProductId = DKIAPKeychain.get(key: subscriptionKey) as? String ?? ""
        if subscriptionProductId == "" {
            DKIAPKeychain.delete(key: self.subscriptionKey)
            DKIAPKeychain.delete(key: self.subscriptionExpiryDateKey)
            return false
        }
        
        // 订阅产品，过期时间
        let DKSubscribedExpiryDateKey = "DKSubscribedExpiryDateKey"
        
        if let subscriptionExpiryDate = DKIAPKeychain.get(key: DKSubscribedExpiryDateKey) as? Date {
            // 已过期
            if subscriptionExpiryDate < Date() {
                DKIAPKeychain.delete(key: self.subscriptionKey)
                DKIAPKeychain.delete(key: self.subscriptionExpiryDateKey)
                return false
            }
        }
        
        if let subscriptionExpiryDate = DKIAPKeychain.get(key: subscriptionExpiryDateKey) as? Date {
            // 已过期
            if subscriptionExpiryDate < Date() {
                DKIAPKeychain.delete(key: self.subscriptionKey)
                DKIAPKeychain.delete(key: self.subscriptionExpiryDateKey)
                return false
            }
        }
        return true
    }
    
    /// 过期时间
    func dk_subscriptionExpiryDate() -> Date? {
        let subscriptionProductId = DKIAPKeychain.get(key: subscriptionKey) as? String ?? ""
        if subscriptionProductId == "" {
            return nil
        }
        if let subscriptionExpiryDate = DKIAPKeychain.get(key: subscriptionExpiryDateKey) as? Date {
            return subscriptionExpiryDate
        }
        
        return nil
    }
    
    func dk_subscriptionExpiryDateString() -> String {
        if dk_isPurchasePermanent { return "永久" }
        let subscriptionProductId = DKIAPKeychain.get(key: subscriptionKey) as? String ?? ""
        if subscriptionProductId == "" {
            return "已过期"
        }
        if let subscriptionExpiryDate = DKIAPKeychain.get(key: subscriptionExpiryDateKey) as? Date {
#if DEBUG
            return Date.dateToString(subscriptionExpiryDate, "yyyy-MM-dd HH:mm")
#else
            return Date.dateToString(subscriptionExpiryDate, "yyyy-MM-dd")
#endif
        } else {
            return "已过期"
        }
    }
}

// MARK: - 永久
extension DKIAPInPurchaseManager {
    
    func dk_buyPermanent(_ product: DKIAPProductModel, _ tryAgin: Bool = true, completion: @escaping (Bool ,Bool) ->Void) {
        guard product.type == .parmanent  else {
            completion(false,false)
            return
        }
        self.dk_purchaseProduct(product.pid, quantity: product.quanlity) { result in
            switch result {
            case .success(let purchase):
                print("永久购买，购买成功")
                let validator = DKAppleReceiptValidatorX()
                SwiftyStoreKit.verifyReceipt(using: validator) { verifyResult in
                    switch verifyResult {
                    case .success(let receipt):
                        _ = SwiftyStoreKit.verifyPurchase(productId: product.pid, inReceipt: receipt)
                        print("永久购买，购买成功，验证成功, ", receipt)
                        self.dk_setPurchasePermanent(isPurchase: true)
                        completion(true, true)
                    case .error(_):
                        completion(true, false)
                    }
                }
            case .deferred(let purchase):
                print("订阅产品\(purchase.productId)，购买成功")
            case .error(let error):
                if tryAgin {
                    self.dk_buySubscription(product, false, completion: completion)
                } else {
                    print("永久购买，购买失败, ", error)
                    completion(false,false)
                }
            }
        }
    }
    
    /// 设置是否永久购买
    func dk_setPurchasePermanent(isPurchase: Bool) {
        DKIAPKeychain.save(key: self.permanentKey, value: isPurchase)
    }
    /// 是否已经永久购买
    var dk_isPurchasePermanent: Bool {
        let permanent = DKIAPKeychain.get(key: permanentKey) as? Bool ?? false
        return permanent
    }
}

// MARK: - 恢复购买
extension DKIAPInPurchaseManager {
    // 恢复购买
    func dk_restore(atomically: Bool = true,completion: @escaping (Bool) -> Void) {
        SwiftyStoreKit.restorePurchases(atomically: atomically) { results in
            if results.restoreFailedPurchases.count > 0 {
                print("恢复购买失败: \(results.restoreFailedPurchases)")
            } else if results.restoredPurchases.count > 0 {
                print("恢复购买成功: \(results.restoredPurchases.count)")
            } else {
                print("恢复购买：什么都没做")
            }
            print("本地已存储的购买信息",SwiftyStoreKit.localReceiptData as Any)
            
            results.restoredPurchases.forEach { purchase in
                // 与订阅购买绑定的下载内容
                let donwloads = purchase.transaction.downloads
                if !donwloads.isEmpty {
                    SwiftyStoreKit.start(donwloads)
                } else if purchase.needsFinishTransaction {
                    SwiftyStoreKit.finishTransaction(purchase.transaction)
                }
            }
            if results.restoredPurchases.count > 0 {
                /// 永久购买
                if let _ = results.restoredPurchases.first(where: { (purchase) -> Bool in
                    return self.productList_permanent.contains { item in
                        return item.pid == purchase.productId
                    }
                }) {
                    self.dk_setPurchasePermanent(isPurchase: true)
                    completion(true)
                    return
                }
                // 订阅
                if let productId = results.restoredPurchases.first?.productId {
                    let validator = DKAppleReceiptValidatorX()
                    SwiftyStoreKit.verifyReceipt(using: validator) { verifyResult in
                        switch verifyResult {
                        case .success(let receipt):
                            let subScriptionResult = SwiftyStoreKit.verifySubscription(ofType: .autoRenewable, productId: productId, inReceipt: receipt)
                            switch subScriptionResult {
                            case .purchased(let expiryDate, let items):
                                if let item = items.first {
                                    self.dk_setPurchaseSubscription(productId: item.productId, expiryDate: expiryDate)
                                    completion(true)
                                }
                            case .expired(let expiryDate, let items):
                                let df = DateFormatter()
                                df.dateFormat = "yyyy-MM-dd HH:mm"
                                print("订阅已过期: \(productId), 过期时间 \(df.string(from: expiryDate)). 订阅项: \(items.count)\n")
                                self.dk_cleanPurchaseSubscription()
                                completion(false)
                            case .notPurchased:
                                self.dk_cleanPurchaseSubscription()
                                completion(false)
                            }
                        case .error(let error):
                            completion(false)
                        }
                    }
                } else {
                    completion(false)
                }
            } else {
                completion(false)
            }
        }
    }
}

extension DKIAPInPurchaseManager {
    
    fileprivate func dk_purchaseProduct(_ productId: String, quantity: Int = 1, atomically: Bool = false, completed: @escaping ((_ result: PurchaseResult) -> Void)) {
        
        SwiftyStoreKit.purchaseProduct(productId, quantity: quantity, atomically: atomically) { (result) in
            switch result {
                // 购买成功
            case .success(let purchase):
                if purchase.needsFinishTransaction {
                    SwiftyStoreKit.finishTransaction(purchase.transaction)
                }
                print("V: 购买成功，需要再次验证订阅结果 - 商品id：", purchase.productId)
            case .error(let error):
                switch error.code {
                case .unknown: print("Unknown error. Please contact support")
                case .clientInvalid: print("Not allowed to make the payment")
                case .paymentCancelled: break
                case .paymentInvalid: print("The purchase identifier was invalid")
                case .paymentNotAllowed: print("The device is not allowed to make the payment")
                case .storeProductNotAvailable: print("The product is not available in the current storefront")
                case .cloudServicePermissionDenied: print("Access to cloud service information is not allowed")
                case .cloudServiceNetworkConnectionFailed: print("Could not connect to the network")
                case .cloudServiceRevoked: print("User has revoked permission to use this cloud service")
                case .privacyAcknowledgementRequired: print("The user needs to acknowledge Apple's privacy policy")
                case .unauthorizedRequestData: print("The app is attempting to use SKPayment's requestData property, but does not have the appropriate entitlement")
                case .invalidOfferIdentifier: print("The specified subscription offer identifier is not valid")
                case .invalidSignature: print("The cryptographic signature provided is not valid")
                case .missingOfferParams: print("One or more parameters from SKPaymentDiscount is missing")
                case .invalidOfferPrice: print("The price of the selected offer is not valid (e.g. lower than the current base subscription price)")
                case .overlayCancelled: break
                case .overlayInvalidConfiguration: break
                case .overlayTimeout: break
                case .ineligibleForOffer: break
                case .unsupportedPlatform: break
                case .overlayPresentedInBackgroundScene: break
                @unknown default: break
                }
            case .deferred(purchase: _):
                break
            }
            completed(result)
        }
    }
}

#else
class DKIAPInPurchaseManager: NSObject {
    static let sharedInstance = DKIAPInPurchaseManager()
}

#endif

#endif


extension Date {
    
    static func dateToString(_ date : Date, _ dateFormat : String = "yyyy-MM-dd HH:mm:ss") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        let date = formatter.string(from: date)
        return date
    }
    
    static func stringToDate(_ string : String, _ dateFormat : String = "yyyy-MM-dd HH:mm:ss") -> Date? {
        let dateFormatter = DateFormatter.init()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let date = dateFormatter.date(from: string)
        return date ?? Date()
    }
}
