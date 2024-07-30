//
//  AHIAPManager.swift
//  DooKit
//
//  Created by Alibaba on 2024/7/25.
//

import UIKit
import SwiftyStoreKit

class AHIAPManager: NSObject {
    
    
    fileprivate let permanentKey = "com.aaaa.iii"
    fileprivate let subscriptionKey = "com.bbbb.iii"
    fileprivate let subscriptionExpiryDateKey = "com.cccc.iii"
    
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
        if ah_isPurchasePermanent || ah_isSubscription { return true }
        return false
    }
    
    static let shared = AHIAPManager()
    
    override init() {
        super.init()
        
        ah_configDefaultData()
        ah_addListnerCallback()
        
    }
}

//MARK: - Public

extension AHIAPManager {
    
    /// 获取商品列表
    func ah_getProductsInfo(productIds: Set<String>, completion: @escaping ([DKIAPProductModel]) ->Void) {
        SwiftyStoreKit.retrieveProductsInfo(productIds) { result in
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
    
    func ah_submitOrder(_ orderInfo: Any?,_ completion: @escaping (Bool ,Bool) ->Void) {
        // 提交订单信息到后台，生成订单
        /// Test
        let success: Bool = true
        let buy_type: Int = 1
        
        if success {
            if buy_type == 1 {
                ah_buySubscription(DKIAPProductModel(), true, "22349862384", .server, completion: completion)
            } else {
                ah_buyPermanent(DKIAPProductModel(), true, "22349862384", completion: completion)
            }
        }
    }
    
    /// 购买订阅
    func ah_buySubscription(_ product: DKIAPProductModel, _ tryAgin: Bool = true, _ orderId: String, _ verifyWay: DKIAPEnumVerifyReceiptURLType,completion: @escaping (Bool ,Bool) ->Void) {
        
        guard SwiftyStoreKit.canMakePayments else {
            completion(false,false)
            return
        }
        
        guard self.ah_isPurchasePermanent == false else {
            completion(false,false)
            return
        }
        
        guard product.type != .consumption && product.type != .parmanent && product.type != .nonRenewed  else {
            completion(false,false)
            return
        }
        self.ah_purchaseProduct(product.pid, quantity: product.quanlity) { result in
            switch result {
            case .success(let purchase):
                self.ah_verifySubscriptionReceipt(product.pid, orderId) { success in
                    if success {
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
                    completion(true, success)
                }
            case .deferred(_):
                
                break
            case .error(_):
                if tryAgin {
                    self.ah_buySubscription(product, false, orderId, verifyWay, completion: completion)
                } else {
                    completion(false,false)
                }
            }
        }
    }
    
    ///  购买永久
    func ah_buyPermanent(_ product: DKIAPProductModel, _ tryAgin: Bool = true, _ orderId: String, completion: @escaping (Bool ,Bool) ->Void) {
        
        guard SwiftyStoreKit.canMakePayments else {
            completion(false,false)
            return
        }
        
        guard product.type == .parmanent  else {
            completion(false,false)
            return
        }
        self.ah_purchaseProduct(product.pid, quantity: product.quanlity) { result in
            switch result {
            case .success(let purchase):
                self.ah_verifyPermanentReceipt(product.pid, orderId) { success in
                    if success {
                        // 验证完成后调用finish
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
                    completion(true,success)
                }
            case .deferred(_):
                break
            case .error(_):
                if tryAgin {
                    self.ah_buyPermanent(product, false, orderId,completion: completion)
                } else {
                    completion(false,false)
                }
            }
        }
    }
    
    
    /// 恢复购买
    func ah_buyRestore(atomically: Bool = false,completion: @escaping (Bool) -> Void) {
        
        SwiftyStoreKit.restorePurchases(atomically: atomically) { results in
            
            if results.restoredPurchases.count > 0 {
                
                results.restoredPurchases.forEach { purchase in
                    // 与订阅购买绑定的下载内容
                    let donwloads = purchase.transaction.downloads
                    if !donwloads.isEmpty {
                        SwiftyStoreKit.start(donwloads)
                    } else if purchase.needsFinishTransaction {
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
                }
                // 永久购买
                if let _ = results.restoredPurchases.first(where: { (purchase) -> Bool in
                    return self.productList_permanent.contains { item in
                        return item.pid == purchase.productId
                    }
                }) {
                    completion(true)
                    return
                }
                // 订阅
                if let productId = results.restoredPurchases.first?.productId {
                    self.ah_verifySubscriptionReceipt(productId, "1231") { success in
                        if let purchase =  results.restoredPurchases.first {
                            SwiftyStoreKit.finishTransaction(purchase.transaction)
                        }
                        completion(success)
                    }
                } else {
                    completion(false)
                }
            } else {
                completion(false)
            }
        }
    }
    
    /// 刷新票据
    func ah_fetchReceipt(forceRefresh: Bool = true, completion: ((Bool)->Void)? = nil) {
        SwiftyStoreKit.fetchReceipt(forceRefresh: forceRefresh) { (result) in
            switch result {
            case .success(_):
                completion?(true)
            case .error(_):
                completion?(false)
            }
        }
    }
}

//MARK: - Private

extension AHIAPManager {
    
    fileprivate func ah_configDefaultData() {
        productList = productList_subscription + productList_permanent
    }
    
    fileprivate func ah_addListnerCallback() {
        
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
        
        SwiftyStoreKit.updatedDownloadsHandler = { downloads in
            let contentURLs = downloads.compactMap { $0.contentURL }
            if contentURLs.count == downloads.count {
                SwiftyStoreKit.finishTransaction(downloads[0].transaction)
            }
        }
    }
    
    /// 购买
    fileprivate func ah_purchaseProduct(_ productId: String, quantity: Int = 1, atomically: Bool = false, completed: @escaping ((_ result: PurchaseResult) -> Void)) {
        
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
    
    /// 连续订阅验证
    fileprivate func ah_verifySubscriptionReceipt(_ productId: String, _ orderId: String, _ verifyWay: DKIAPEnumVerifyReceiptURLType = .server, completion: @escaping(Bool) -> Void) {
        var appleValidator: AppleReceiptValidator!
#if DEBUG
        appleValidator = AppleReceiptValidator(service: .sandbox, sharedSecret: shareSecret)
#else
        if verifyWay == .server {
            appleValidator = AHIAPManagerReceiptValidator(orderId: "427984789237", productId: productId, needSavaReceiptData: true, userId: "JFHSJKPOFNDMHUE2638746")
        } else {
            appleValidator = AppleReceiptValidator(service: .production, sharedSecret: shareSecret)
        }
#endif
        SwiftyStoreKit.verifyReceipt(using: appleValidator) { verifyResult in
            switch verifyResult {
            case .success(let receipt):
                let subScriptionResult = SwiftyStoreKit.verifySubscription(ofType: .autoRenewable, productId: productId, inReceipt: receipt)
                switch subScriptionResult {
                case .purchased(let expiryDate, let items):
                    if let item = items.first {
                        self.ah_savePurchaseSubscription(productId: item.productId, expiryDate: expiryDate)
                        completion(true)
                    }
                case .expired(_, _):
                    self.ah_cleanPurchaseSubscription()
                    completion(false)
                case .notPurchased:
                    self.ah_cleanPurchaseSubscription()
                    completion(false)
                }
            case .error(_):
                self.ah_cleanPurchaseSubscription()
                completion(false)
            }
        }
    }
    
    /// 买断永久验证
    fileprivate func ah_verifyPermanentReceipt(_ productId: String, _ orderId: String, _ verifyWay: DKIAPEnumVerifyReceiptURLType = .server, completion: @escaping(Bool) -> Void) {
        var appleValidator: AppleReceiptValidator!
#if DEBUG
        appleValidator = AppleReceiptValidator(service: .sandbox, sharedSecret: shareSecret)
#else
        if verifyWay == .server {
            appleValidator = AHIAPManagerReceiptValidator(orderId: "427984789237", productId: productId, needSavaReceiptData: true, userId: "JFHSJKPOFNDMHUE2638746")
        } else {
            appleValidator = AppleReceiptValidator(service: .production, sharedSecret: shareSecret)
        }
#endif
        SwiftyStoreKit.verifyReceipt(using: appleValidator) { verifyResult in
            switch verifyResult {
            case .success(let receipt):
                let purchaseResult = SwiftyStoreKit.verifyPurchase(productId: productId, inReceipt: receipt)
                switch purchaseResult {
                case .purchased(_):
                    self.ah_savePurchasePermanent(isPurchase: true)
                    completion(true)
                case .notPurchased:
                    completion(false)
                }
            case .error(_):
                completion(false)
            }
        }
    }
}

//MARK: - SavaLocal
extension AHIAPManager {
    
    //MARK: - Subscription
    
    /// 设置是否订阅
    fileprivate func ah_savePurchaseSubscription(productId: String, expiryDate: Date? = nil) {
        AHIAPManagerKeyChain.save(key: self.subscriptionKey, value: productId)
        AHIAPManagerKeyChain.save(key: self.subscriptionExpiryDateKey, value: expiryDate as Any)
    }
    /// 获取购买商品的 id
    fileprivate func ah_getPurchaseProductId() -> String? {
        if let productId = AHIAPManagerKeyChain.get(key: subscriptionKey) as? String{
            return productId
        }
        return nil
    }
    /// 清除订阅保存信息
    fileprivate func ah_cleanPurchaseSubscription() {
        AHIAPManagerKeyChain.delete(key: self.subscriptionKey)
        AHIAPManagerKeyChain.delete(key: self.subscriptionExpiryDateKey)
    }
    /// 是否已经订阅
    fileprivate var ah_isSubscription: Bool {
        let subscriptionProductId = AHIAPManagerKeyChain.get(key: subscriptionKey) as? String ?? ""
        if subscriptionProductId == "" {
            ah_cleanPurchaseSubscription()
            return false
        }
        
        // 订阅产品，过期时间
        if let subscriptionExpiryDate = ah_subscriptionExpiryDate() {
            // 已过期
            if subscriptionExpiryDate < Date() {
                ah_cleanPurchaseSubscription()
                return false
            }
        }
        return true
    }
    
    /// 过期时间
    func ah_subscriptionExpiryDate() -> Date? {
        let subscriptionProductId = AHIAPManagerKeyChain.get(key: subscriptionKey) as? String ?? ""
        if subscriptionProductId == "" {
            return nil
        }
        if let subscriptionExpiryDate = AHIAPManagerKeyChain.get(key: subscriptionExpiryDateKey) as? Date {
            return subscriptionExpiryDate
        }
        
        return nil
    }
    
    func ah_subscriptionExpiryDateString() -> String {
        if ah_isPurchasePermanent { return "永久" }
        let subscriptionProductId = AHIAPManagerKeyChain.get(key: subscriptionKey) as? String ?? ""
        if subscriptionProductId == "" {
            return "已过期"
        }
        if let subscriptionExpiryDate = AHIAPManagerKeyChain.get(key: subscriptionExpiryDateKey) as? Date {
#if DEBUG
            return Date.dateToString(subscriptionExpiryDate, "yyyy-MM-dd HH:mm")
#else
            return Date.dateToString(subscriptionExpiryDate, "yyyy-MM-dd")
#endif
        } else {
            return "已过期"
        }
    }
    
    
    //MARK: - Permanent
    /// 设置是否永久购买
    func ah_savePurchasePermanent(isPurchase: Bool) {
        AHIAPManagerKeyChain.save(key: self.permanentKey, value: isPurchase)
    }
    
    /// 是否已经永久购买
    var ah_isPurchasePermanent: Bool {
        let permanent = AHIAPManagerKeyChain.get(key: permanentKey) as? Bool ?? false
        return permanent
    }
}
