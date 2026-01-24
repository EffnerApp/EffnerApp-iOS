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
    
    var isCheckingAuthorization: Bool = true
    
    // Helper method to set the primary class (moves it to the first position)
    @MainActor
    func setPrimaryClass(_ className: String) {
        guard var currentUser = user else { return }
        
        // Remove the class from its current position and add it to the front
        var updatedKlasses = currentUser.klasses.filter { $0 != className }
        updatedKlasses.insert(className, at: 0)
        
        if currentUser.klasses != updatedKlasses {
            currentUser.klasses = updatedKlasses
            currentUser.saveKlasses()
            self.user = currentUser
        }
    }
    
    // Helper method to update multiple classes
    @MainActor
    func updateUserKlasses(_ newKlasses: [String]) {
        guard var currentUser = user else { return }
        let oldKlasses = currentUser.klasses
        
        if oldKlasses != newKlasses {
            currentUser.klasses = newKlasses
            currentUser.saveKlasses()
            self.user = currentUser
        }
    }
    
    private init() {
        // Initialize the UserSessions
        user = loadUserFromStorage();
        
        guard let user else {
            print("No user found in storage.")
            isCheckingAuthorization = false
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
            self.isCheckingAuthorization = false
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
        let klasses = UserDefaults.standard.stringArray(forKey: "userKlasses")
        guard let klasses = klasses else {
            print("No Klasses found in UserDefaults.")
            return nil
        }
        // Set user
        return User(id: account, password: password, klasses: klasses, isAuthorized: true)
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
    var klasses: [String] = [] // List of classes the user is in
    
    var isAuthorized: Bool = false
    
    // Computed property to get the primary class (first in list or fallback to klass)
    var primaryClass: String? {
        return klasses.first
    }
    
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
    
    func saveKlasses() {
        UserDefaults.standard.set(klasses, forKey: "userKlasses")
    }
    
    func clearCredentials() {
        // Remove credentials from Keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "de.effnerapp.effnerapp",
            kSecAttrAccount as String: id
        ]
        SecItemDelete(query as CFDictionary)
        // Remove Klasses from UserDefaults
        UserDefaults.standard.removeObject(forKey: "userKlasses")
    }
    
}
