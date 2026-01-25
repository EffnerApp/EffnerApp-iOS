//
//  KeyChainUtil.swift
//  EffnerApp
//
//  Created by Luis Bros on 25.01.26.
//

import Foundation

struct KeyChainItem: Codable {
    let key: String
    let value: String
}

struct KeyChainUtil {
    
    public static func loadFromKeyChain(serviceName: String) -> KeyChainItem? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let existingItem = item as? [String: Any],
              let account = existingItem[kSecAttrAccount as String] as? String,
              let passwordData = existingItem[kSecValueData as String] as? Data,
              let password = String(data: passwordData, encoding: .utf8) else {
            print("No credentials found in keychain for service \(serviceName)")
            return nil
        }
        
        return KeyChainItem(key: account, value: password)
    }
    
    public static func saveToKeyChain(serviceName: String, item: KeyChainItem) -> Bool {
        let account = item.key
        let passwordData = item.value.data(using: .utf8) ?? Data()
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecValueData as String: passwordData
        ]
        
        SecItemDelete(query as CFDictionary) // Remove any existing item
        
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Error saving credentials for service \(serviceName): \(status)")
            return false
        } else {
            print("Credentials saved successfully for service \(serviceName)")
            return true
        }
    }
    
    public static func deleteFromKeyChain(serviceName: String, username: String) {
        // Remove credentials from Keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: username
        ]
        SecItemDelete(query as CFDictionary)
    }
        
    
}
