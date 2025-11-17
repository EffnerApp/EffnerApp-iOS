//
//  User.swift
//  EffnerApp
//
//  Created by Luis Bros on 21.07.25.
//
import SwiftUI
import Observation
import Security

@Observable
class UserSession: ObservableObject {
    static let shared = UserSession()
    
    var user: User? = nil {
        didSet {
            objectWillChange.send()
        }
    }
    
    // Helper method to update class and trigger cache refresh
    @MainActor
    func updateUserKlass(_ newKlass: String) {
        guard var currentUser = user else { return }
        let olKClass = currentUser.klass
        
        if olKClass != newKlass {
            currentUser.klass = newKlass
            currentUser.saveKlass()
            self.user = currentUser
            
            // Trigger cache refresh
            Task { @MainActor in
                await ExamsCache.shared.refreshCache()
                await SubstitutionsCache.shared.refreshCache()
                await TimetablesCache.shared.refreshCache()
            }
        }
    }
    
    private init() {
        // Initialize the UserSessions
        user = loadUserFromStorage();
        
        guard let user else {
            print("No user found in storage.")
            return
        }
        
        Task { @MainActor in
            let isAuthorized = await AuthService().authorize(user: user)
            switch isAuthorized {
                case .success(let authorized):
                    if authorized {
                        print("User is authorized.")
                        self.user?.isAuthorized = true
                    }
                case .failure(let error):
                    print("Authorization failed with error: \(error)")
                    self.user = nil
                }
        }
        
    }
    
    func loadUserFromStorage() -> User? {
        // Keychain query for id and password
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "de.effnerapp.effnerapp",
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
            print("No credentials found in keychain.")
            return nil
        }
        // UserDefaults for classA
        let classA = UserDefaults.standard.string(forKey: "userClassA")
        guard let classA = classA else {
            print("No classA found in UserDefaults.")
            return nil
        }
        // Set user
        return User(id: account, password: password, klass: classA, isAuthorized: false)
    }
    
    @MainActor
    func logout() {
        // Clear user session
        user?.clearCredentials()
        user = nil
        print("User logged out and credentials cleared.")
    }
}


struct User: Codable {
    var id: String
    var password: String
    var klass: String
    
    var isAuthorized: Bool = false
    
    func generateAuth() -> Authentication {
        return Authentication(user: self)
    }
    
    func saveCredentials() {
        let account = id
        let passwordData = password.data(using: .utf8) ?? Data()
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "de.effnerapp.effnerapp",
            kSecAttrAccount as String: account,
            kSecValueData as String: passwordData
        ]
        
        SecItemDelete(query as CFDictionary) // Remove any existing item
        
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Error saving credentials: \(status)")
        } else {
            print("Credentials saved successfully.")
        }
    }
    
    func saveKlass() {
        UserDefaults.standard.set(klass, forKey: "userClassA")
    }
    
    func clearCredentials() {
        // Remove credentials from Keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "de.effnerapp.effnerapp",
            kSecAttrAccount as String: id
        ]
        SecItemDelete(query as CFDictionary)
        // Remove classA from UserDefaults
        UserDefaults.standard.removeObject(forKey: "userClassA")
    }
    
}
