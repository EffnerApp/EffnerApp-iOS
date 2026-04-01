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
    
    //var user: User? = nil {
     //   didSet {
      //      objectWillChange.send()
      //  }
    //}
    var user: User? = nil
    var isCheckingAuthorization: Bool = true
    var subjectSelectionsVersion: Int = 0
    
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
            
            // notify caches
            objectWillChange.send()
        }
    }
    
    @MainActor
    func setUser(user: User) {
        self.user = user
        
        // notify the caches
        objectWillChange.send()
    }

    
    // Helper method to set the primary class (moves it to the first position)
    @MainActor
    func setPrimaryClass(_ className: String) {
        // Remove the class from its current position and add it to the front
        var updatedKlasses = user!.klasses.filter { $0 != className }
        updatedKlasses.insert(className, at: 0)
        
        if user!.klasses != updatedKlasses {
            user!.klasses = updatedKlasses
            user!.saveKlasses()
        }
        
        // notify the caches
        objectWillChange.send()
    }
    
    // Helper method to update multiple classes
    func updateUserKlasses(_ newKlasses: [String]) {
        let oldKlasses = user!.klasses
        
        if oldKlasses != newKlasses {
            user!.klasses = newKlasses
            user!.saveKlasses()
            
            Task {
                if await NotificationService.shared.isEnabled {
                    _ = await NotificationService.shared.updateKlasses(klasses: newKlasses)
                }
            }
        }
    }
    
    func loadUserFromStorage() -> User? {
        // Keychain query for id and password
        let cred: KeyChainItem? = KeyChainUtil.loadFromKeyChain(serviceName: Constants.bundleIdentifier)
        let ssbCred: KeyChainItem? = KeyChainUtil.loadFromKeyChain(serviceName: Constants.bundleIdentifier + ".ssb")
        
        // UserDefaults for userKlasses
        let klasses = UserDefaults.standard.stringArray(forKey: "userKlasses")
        guard let klasses = klasses else {
            print("No Klasses found in UserDefaults.")
            return nil
        }
        
        // Set user
        return User(ssbId: ssbCred?.key ?? "", ssbToken: ssbCred?.value ?? "", username: cred?.key ?? "", password: cred?.value ?? "", klasses: klasses, isAuthorized: true)
    }
    
    @MainActor
    func logout() {
        // Clear user session
        user?.clearCredentials()
        user?.clearSSBCredentials()
        
        NotificationService.shared.disableNotifications()
        user = nil
        print("User logged out and credentials cleared.")
        
        // notify caches
        objectWillChange.send()
    }
}


struct User: Codable {
    var ssbId: String
    var ssbToken: String
    
    var username: String
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
    
    func generateSSBBasicAuth() -> Authentication {
        return Authentication.ssbBasic(username: username, password: password)
    }
    
    func generateSSBTokenAuth() -> Authentication {
        return Authentication.ssbToken(id: ssbId, token: ssbToken)
    }
    
     func saveSSBCredentials() {
        _ = KeyChainUtil.saveToKeyChain(serviceName: Constants.bundleIdentifier + ".ssb", item: KeyChainItem(key: ssbId, value: ssbToken))
    }
    
    mutating func clearSSBCredentials() {
        // Remove SSB credentials from Keychain
        KeyChainUtil.deleteFromKeyChain(serviceName: Constants.bundleIdentifier + ".ssb")
        
        ssbId = ""
        ssbToken = ""
    }
    
    func saveCredentials() {
        _ = KeyChainUtil.saveToKeyChain(serviceName: Constants.bundleIdentifier, item: KeyChainItem(key: username, value: password))
    }
    
    func clearCredentials() {
        // Remove credentials from Keychain
        KeyChainUtil.deleteFromKeyChain(serviceName: Constants.bundleIdentifier)
        // Remove Klasses from UserDefaults
        UserDefaults.standard.removeObject(forKey: "userKlasses")
        // Remove subject selections for all classes
        for klass in klasses {
            UserDefaults.standard.removeObject(forKey: "subjectSelections_\(klass)")
        }
    }
    
    func saveKlasses() {
        UserDefaults.standard.set(klasses, forKey: "userKlasses")
    }
    
    // MARK: - Subject Selections (Fächerauswahl im Stundenplan)
    
    /// Speichert die Fächerauswahl für die aktuelle primaryClass
    func saveSubjectSelections(_ selections: [String: String]) {
        guard let className = primaryClass else { return }
        let key = "subjectSelections_\(className)"
        if let data = try? JSONEncoder().encode(selections) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    /// Lädt die Fächerauswahl für die aktuelle primaryClass
    func loadSubjectSelections() -> [String: String] {
        guard let className = primaryClass else { return [:] }
        let key = "subjectSelections_\(className)"
        guard let data = UserDefaults.standard.data(forKey: key),
              let selections = try? JSONDecoder().decode([String: String].self, from: data) else {
            return [:]
        }
        return selections
    }
    
}
