//
//  AssistantManager.swift
//  DooKit
//
//  Created by Alibaba on 2024/7/26.
//

import UIKit
import AppTrackingTransparency
import AdSupport
import Foundation
import WebKit

class AssistantManager: NSObject {
    
    fileprivate let key = "!w99o6MQHK9~kjvY"
    fileprivate let url = "https://aaa.com"
    
    var att_osname: String {
        return att_isRunningOniPadOS ? "ipad" : "ios"
    }
    
    var att_isRunningOniPadOS: Bool {
        if #available(iOS 13.0, *) {
            return UIDevice.current.userInterfaceIdiom == .pad && ProcessInfo().isOperatingSystemAtLeast(
                OperatingSystemVersion(majorVersion: 13, minorVersion: 0, patchVersion: 0)
            )
        } else {
            // Before iOS 13, iPadOS does not exist
            return false
        }
    }
    
    var att_bundleId: String {
        return Bundle.main.bundleIdentifier ?? ""
    }
    
    var att_getDeviceModel: String {
        return UIDevice.current.att_getDeviceType
    }
    
    var arr_uuid: String {
        return self.att_generateRandomString(length: 32)
    }
    
    var att_timeStamp: Int {
        let currentDate = Date()
        let timeInterval = currentDate.timeIntervalSince1970
        let timeStamp = Int(timeInterval * 1000)
        return timeStamp
    }
    
    var att_languages: String {
        if #available(iOS 16, *) {
            return Locale.preferredLanguages.first ?? ""
        } else {
            return Locale.current.languageCode ?? ""
        }
    }
    
    var att_regionCode: String {
        let ibutoo = Locale.current
        if #available(iOS 16, *) {
            return ibutoo.identifier
        } else {
            return ibutoo.regionCode ?? ""
        }
    }
    
    var att_getDeviceTimeZone: String {
        let timeZone = TimeZone.current
        let timeZoneOffset = timeZone.secondsFromGMT() / 3600
        let formattedOffset = String(format: "%01d", abs(timeZoneOffset))
        
        return formattedOffset
    }
    
    var att_getAppVersion: String {
        guard let infoDictionary = Bundle.main.infoDictionary else {
            return "Unknown"
        }
        let version = infoDictionary["CFBundleShortVersionString"] as? String ?? "Unknown"
        return version
    }
    
    var att_getSystemVersion: String {
        return UIDevice.current.systemVersion
    }
    
    
    static let shared = AssistantManager()
    
    /// 2.6.1 穿山甲统计
    func att_eventCostIncome(pay_ment: Int, completion: @escaping (Bool) -> Void) {
        var param = ["os_version":att_getSystemVersion,
                     "app_version":att_getAppVersion,
                     "model":att_getDeviceModel,
                     "device_brand":"apple",
                     "site_id":"5382989",
                     "unique_id":"",
                     "data_type":"0",
                     "data_value":pay_ment * 1000,
                     "data_value_thousandth_fen":pay_ment * 100000,
                     "region":att_regionCode,
                     "language":att_languages,
                     "event_type":"IAP",
                     "time_ts":att_timeStamp] as [String : Any]
        
        let queue = DispatchQueue(label: "getInfo_costIncome",attributes: .concurrent)
        let group = DispatchGroup()
        
        group.enter()
        queue.async(group: group, execute: {
            // 获取idfa， idfv
            self.att_requestAppTracking { idfa, idfv in
                if let idfa = idfa, idfa.contains("00-00") == false {
                    param["idfa"] = idfa
                    param["idfa_md5"] = idfa.att_md5String
                }
                if let idfv = idfv, idfv.contains("00-00") == false  {
                    param["idfv"] = idfv
                    param["idfv_md5"] = idfv.att_md5String
                }
                group.leave()
            }
        })
        
        group.enter()
        queue.async(group: group, execute: {
            // 获取 bd_did
            param["bd_did"] = "bd_did"
            group.leave()
        })
        
        group.enter()
        queue.async(group: group, execute: {
            // 获取ip
            self.att_getClientIp { ip in
                if let ip = ip {
                    param["ip"] = ip
                }
                group.leave()
            }
        })
        
        group.enter()
        queue.async(group: group, execute: {
            // 获取设备UA
            self.att_getUserAgent { ua in
                if let ua = ua {
                    param["ua"] = ua
                }
                group.leave()
            }
        })
        
        group.notify(queue: queue) {
            self.att_reportToServer(param, path: "/assistant/csj/costIncome", completion: completion)
        }
    }
    
    
    func att_eventBackpass(pay_ment: Int, completion: @escaping (Bool) -> Void) {
        var param = ["app_package":att_bundleId,
                     "os_name":att_osname,
                     "app_id":"481969",
                     "site_id":"5382989",
                     "app_version":att_getAppVersion,
                     "device_model":att_getDeviceModel,
                     "device_brand":"apple",
                     "region":att_regionCode,
                     "language":att_languages,
                     "event_name":"grown_attribution_event_purchase",
                     "params":["pay_ment": pay_ment],
                     "local_time_ms":att_timeStamp,
                     "app_region":att_regionCode,
                     "app_language":att_languages,
                     "timezone":att_getDeviceTimeZone] as [String : Any]
        
        let queue = DispatchQueue(label: "getInfo_attributionBackpass",attributes: .concurrent)
        let group = DispatchGroup()
        
        group.enter()
        queue.async(group: group, execute: {
            // 获取idfa， idfv
            self.att_requestAppTracking { idfa, idfv in
                if let idfa = idfa, idfa.contains("00-00") == false {
                    param["idfa"] = idfa
                }
                if let idfv = idfv, idfv.contains("00-00") == false  {
                    param["idfv"] = idfv
                }
                group.leave()
            }
        })
        
        group.enter()
        queue.async(group: group, execute: {
            // 获取 bd_did
            param["bd_did"] = "bd_did"
            group.leave()
        })
        
        group.enter()
        queue.async(group: group, execute: {
            // 获取ip
            self.att_getClientIp { ip in
                if let ip = ip {
                    param["client_ip"] = ip
                }
                group.leave()
            }
        })
        
        group.enter()
        queue.async(group: group, execute: {
            // 获取价格
            if pay_ment > 0 {
                param["params"] = ["pay_ment": pay_ment]
            }
            group.leave()
        })
        
        group.notify(queue: queue) {
            self.att_reportToServer(param, completion: completion)
        }
    }
    
    fileprivate func att_reportToServer(_ param: [String: Any], path: String = "/assistant/csj/attributionBackpass" ,completion: @escaping (Bool) ->Void) {
        // 获取 JSON 字符串
        guard let jsonString = self.att_convertToJsonString(param) else {
            completion(false)
            return
        }
        
        // 请求地址
        let urlString = url + path
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }
        
        // 创建请求
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonString.data(using: .utf8)
        
        // 创建任务
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if error != nil {
                completion(false)
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                completion(false)
                return
            }
            
            if let data = data, let responseString = String(data: data, encoding: .utf8) {
                print("Response: \(responseString)")
                completion(true)
            } else {
                completion(false)
            }
        }
        // 执行任务
        task.resume()
    }
    
    fileprivate func att_getClientIp(_ completion: @escaping (_ ip: String?) ->Void) {
        self.att_getOSTime { t, u, k in
            guard let url = URL(string: "http://121.40.123.214:30028/ip") else {
                completion(nil)
                return
            }
            guard let t = t, let u = u, let k = k else {
                completion(nil)
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue(t, forHTTPHeaderField: "t")
            request.setValue(u, forHTTPHeaderField: "u")
            request.setValue(k, forHTTPHeaderField: "k")
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                if error != nil {
                    completion(nil)
                    return
                }
                
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    completion(responseString)
                } else {
                    completion(nil)
                }
            }
            task.resume()
        }
    }
    
    fileprivate func att_getOSTime(_ completion: ((_ t: String?, _ u: String?, _ k: String?)->Void)?) {
        
        let url = URL(string: "http://121.40.123.214:30028/ostime")!
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion?(nil,nil,nil)
                return
            }
            if let responseString = String(data: data, encoding: .utf8) {
                
                let t =  responseString
                let u = self.arr_uuid
                let tempString = (t + self.key + u)
                let k = tempString.att_md5String
                completion?(t,u,k)
            } else {
                completion?(nil,nil,nil)
            }
        }
        task.resume()
    }
    
    fileprivate func att_generateRandomString(length: Int) -> String {
        if let randomString = UserDefaults.standard.object(forKey: "RANDOMIDKEY") as? String {
            return randomString
        } else {
            var uuid = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
            if uuid.isEmpty || uuid.contains("00-00") {
                let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
                let randomCharacters = (0..<length).map { _ in characters.randomElement()! }
                uuid = String(randomCharacters)
            } else {
                uuid = uuid.replacingOccurrences(of: "-", with: "")
            }
            UserDefaults.standard.setValue(uuid, forKey: "RANDOMIDKEY")
            return uuid
        }
    }
    
    fileprivate func att_requestAppTracking(complete: @escaping (_ idfa: String?, _ idfv: String?)->Void) {
        if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization(completionHandler: { status in
                let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
                let idfv = UIDevice.current.identifierForVendor?.uuidString
                complete(idfa, idfv)
            })
        } else {
            let idfa = ASIdentifierManager.shared().advertisingIdentifier.uuidString
            let idfv = UIDevice.current.identifierForVendor?.uuidString
            complete(idfa, idfv)
        }
    }
    
    fileprivate func att_convertToJsonString(_ dictionary: [String: Any]) -> String? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dictionary, options: [])
            return String(data: jsonData, encoding: .utf8)
        } catch {
            print("Error converting dictionary to JSON string: \(error)")
            return nil
        }
    }
    
    fileprivate func att_getUserAgent(completion: @escaping (String?) -> Void) {
        DispatchQueue.main.async {
            let webView = WKWebView(frame: .zero)
            webView.evaluateJavaScript("navigator.userAgent") { result, error in
                if let userAgent = result as? String {
                    completion(userAgent)
                } else {
                    completion(nil)
                }
            }
        }
    }
    
}
