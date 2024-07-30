//
//  DKAppleReceiptValidatorX.swift
//  DooKit
//
//  Created by Alibaba on 2024/7/24.
//

import Foundation
import SwiftyStoreKit

public class DKAppleReceiptValidatorX: ReceiptValidator {
    
    public func validate(receiptData: Data, completion: @escaping (VerifyReceiptResult) -> Void) {
        let storeURL = URL(string: "")!
        let storeRequest = NSMutableURLRequest(url: storeURL)
        storeRequest.httpMethod = "POST"
        var headers: [String: String] = [:]
        headers["Content-Type"] = "application/json;charset=UTF-8"
        headers["clientId"] = "1"
        headers["userId"] = "123"
        storeRequest.allHTTPHeaderFields = headers
        
        // body
        let receipt = receiptData.base64EncodedString(options: [])
        let requestContents: NSMutableDictionary = [ "receipt": receipt ]
#if DEBUG
        requestContents.setValue("Sandbox", forKey: "environment")
#else
        requestContents.setValue("Product", forKey: "environment")
#endif
        // Encore request body
        do {
            storeRequest.httpBody = try JSONSerialization.data(withJSONObject: requestContents, options: [])
        } catch let e {
            completion(.error(error: .requestBodyEncodeError(error: e)))
            return
        }
        
        // Remote task
        let task = URLSession.shared.dataTask(with: storeRequest as URLRequest) { data, _, error -> Void in
            // there is an error
            if let networkError = error {
                completion(.error(error: .networkError(error: networkError)))
                return
            }
            
            // there is no data
            guard let safeData = data else {
                completion(.error(error: .noRemoteData))
                return
            }
            
            // cannot decode data
            guard let receiptResultInfo = try? JSONSerialization.jsonObject(with: safeData, options: .mutableLeaves) as? ReceiptInfo ?? [:] else {
                let jsonStr = String(data: safeData, encoding: String.Encoding.utf8)
                completion(.error(error: .jsonDecodeError(string: jsonStr)))
                return
            }
            
            let code = receiptResultInfo["code"] as? Int ?? -1
            let receiptInfo = receiptResultInfo["data"] as? ReceiptInfo ?? [:]
            
            // get status from info
            if let status = receiptInfo["status"] as? Int {
                /*
                 * http://stackoverflow.com/questions/16187231/how-do-i-know-if-an-in-app-purchase-receipt-comes-from-the-sandbox
                 * How do I verify my receipt (iOS)?
                 * Always verify your receipt first with the production URL; proceed to verify
                 * with the sandbox URL if you receive a 21007 status code. Following this
                 * approach ensures that you do not have to switch between URLs while your
                 * application is being tested or reviewed in the sandbox or is live in the
                 * App Store.
                 
                 * Note: The 21007 status code indicates that this receipt is a sandbox receipt,
                 * but it was sent to the production service for verification.
                 */
                let receiptStatus = ReceiptStatus(rawValue: status) ?? ReceiptStatus.unknown
                if receiptStatus == .valid {
                    completion(.success(receipt: receiptInfo))
                } else {
                    completion(.error(error: .receiptInvalid(receipt: receiptInfo, status: receiptStatus)))
                }
            } else {
                completion(.error(error: .receiptInvalid(receipt: receiptInfo, status: ReceiptStatus.none)))
            }
        }
        task.resume()
    }
    
    
}
