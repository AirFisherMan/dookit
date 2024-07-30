//
//  DKIAPKeychain.swift
//  DooKit
//
//  Created by Alibaba on 2024/7/24.
//

import Foundation

class DKIAPKeychain: NSObject {
    // TODO: 创建查询条件
    private class func createKeychainQuery(_ service: String, _ account: String) -> NSMutableDictionary {
        // 创建一个条件字典
        let keychainQuery = NSMutableDictionary.init(capacity: 0)
        // 设置条件存储的类型
        keychainQuery.setValue(kSecClassGenericPassword, forKey: kSecClass as String)
        // 设置存储数据的标记
        keychainQuery.setValue(service, forKey: kSecAttrService as String)
        keychainQuery.setValue(account, forKey: kSecAttrAccount as String)
        // 设置数据访问属性
        keychainQuery.setValue(kSecAttrAccessibleAfterFirstUnlock, forKey: kSecAttrAccessible as String)
        // 返回创建条件字典
        return keychainQuery
    }
}
// MARK: public 增删改查
extension DKIAPKeychain {
    // MARK: 存储数据
    @discardableResult
    class func save(key: String, value: Any) -> Bool {
        // 获取存储数据的条件
        let keychainQuery = self.createKeychainQuery(key, key)
        // 删除旧的存储数据
        SecItemDelete(keychainQuery)
        // 设置数据
        keychainQuery.setValue(NSKeyedArchiver.archivedData(withRootObject: value), forKey: kSecValueData as String)
        // 进行存储数据
        let saveState = SecItemAdd(keychainQuery, nil)
        if saveState == noErr  {
           return true
        }
        return false
    }
    // MAKR: 更新数据
    @discardableResult
    class func update(key: String, value: Any) -> Bool {
        // 获取更新的条件
        let keychainQuery = self.createKeychainQuery(key, key)
        // 创建数据存储字典
        let updateQuery = NSMutableDictionary.init(capacity: 0)
        // 设置数据
        updateQuery.setValue(NSKeyedArchiver.archivedData(withRootObject: value), forKey: kSecValueData as String)
        // 更新数据
        let updataStatus = SecItemUpdate(keychainQuery, updateQuery)
        if updataStatus == noErr {
            return true
        }
        return false
    }
    // MAKR: 获取数据
    class func get(key: String) -> Any {
        var idObject: Any?
        // 获取查询条件
        let keychainQuery = self.createKeychainQuery(key, key)
        // 提供查询数据的两个必要参数
        keychainQuery.setValue(kCFBooleanTrue, forKey: kSecReturnData as String)
        keychainQuery.setValue(kSecMatchLimitOne, forKey: kSecMatchLimit as String)
        // 创建获取数据的引用
        var queryResult: AnyObject?
        // 通过查询是否存储在数据
        let readStatus = withUnsafeMutablePointer(to: &queryResult) { SecItemCopyMatching(keychainQuery, UnsafeMutablePointer($0))}
        if readStatus == errSecSuccess {
            if let data = queryResult as! NSData? {
                idObject = NSKeyedUnarchiver.unarchiveObject(with: data as Data) as Any
            }
        }
        return idObject as Any
    }
    // MARK: 删除数据
    class func delete(key: String) {
        // 获取删除的条件
        let keychainQuery = self.createKeychainQuery(key, key)
        // 删除数据
        SecItemDelete(keychainQuery)
    }
}
