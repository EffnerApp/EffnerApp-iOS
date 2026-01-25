//
//  NotificationService.swift
//  EffnerApp
//
//  Created by Luis Bros on 05.01.26.
//

import Foundation
import UserNotifications
import UIKit

@MainActor
class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var error: NetworkError?
    private let networkManager : NetworkManager

    @Published var isEnabled: Bool = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var deviceToken: String? = nil
    
    private init(networkManager: NetworkManager = NetworkManager.shared) {
        self.networkManager = networkManager
        print("NotificationService initialized")
        Task {
            await checkAuthorizationStatus()
        }
    }
    
    /// Überprüft den aktuellen Autorisierungsstatus
    func checkAuthorizationStatus() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        
        authorizationStatus = settings.authorizationStatus
        let notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        guard notificationsEnabled else {
            isEnabled = false
            return
        }
        isEnabled = notificationsEnabled && (authorizationStatus == .authorized)
    }
    
    /// Fordert die Benachrichtigungsberechtigung an (wenn noch nicht geschehen)
    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            
            if granted {
                // Registriere für Remote Notifications
                UIApplication.shared.registerForRemoteNotifications()
                UserDefaults.standard.set(true, forKey: "notificationsEnabled")
                await checkAuthorizationStatus()
                return true
            } else {
                await checkAuthorizationStatus()
                return false
            }
        } catch {
            print("Permission Error: \(error.localizedDescription)")
            await checkAuthorizationStatus()
            return false
        }
    }
    
    /// Aktiviert Benachrichtigungen (fordert Berechtigung an, falls nötig)
    func enableNotifications() async -> Bool {
        await checkAuthorizationStatus()
        
        switch authorizationStatus {
        case .notDetermined, .authorized:
            return await requestPermission()
            
        case .denied, .provisional, .ephemeral:
            // Berechtigung wurde verweigert oder ist eingeschränkt
            isEnabled = false
            return false
            
        @unknown default:
            isEnabled = false
            return false
        }
    }
    
    /// Deaktiviert Benachrichtigungen
    func disableNotifications() {
        Task {
            await deleteUser()
        }
        isEnabled = false
        UserDefaults.standard.set(false, forKey: "notificationsEnabled")
    }
    
    /// Öffnet die Einstellungen der App, damit der User Berechtigungen ändern kann
    func openAppSettings() {
        if let appSettings = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(appSettings) {
                UIApplication.shared.open(appSettings)
            }
        }
    }
    
    
    func createUser() async -> Result<SSBUserResponse, NetworkError> {
        do {
            guard deviceToken != nil else {
                self.error = .clientError(statusCode: 400, msg: "Device token is nil.")
                return .failure(self.error!)
            }
            let ssbUserRequest = SSBUserRequest(deviceToken: deviceToken!, classes: UserSession.shared.user?.klasses ?? [])
            
            let ssbUserResponse: SSBUserResponse = try await networkManager.fetch(from: CreateUserEndpoint(ssbUserRequest: ssbUserRequest))
            
            UserSession.shared.user?.saveSSBCredentials(id: ssbUserResponse.id, token: ssbUserResponse.token)
            
            return .success(ssbUserResponse)
        } catch let networkError as NetworkError {
            self.error = networkError
            return .failure(self.error!)
        } catch(let error) {
            self.error = .unknownError(statusCode: 0, msg: error.localizedDescription)
            return .failure(self.error!)
        }
    }
    
    func deleteUser() async -> Result<Bool, NetworkError> {
        do {
            let _result: Bool = try await networkManager.fetch(from: DeleteUserEndpoint())
            
            guard _result else {
                self.error = .serverError(statusCode: 500, msg: "Failed to delete user on server.")
                return .failure(self.error!)
            }
            
            UserSession.shared.user?.clearSSBCredentials()
            
            return .success(_result)
        } catch let networkError as NetworkError {
            self.error = networkError
            return .failure(self.error!)
        } catch(let error) {
            self.error = .unknownError(statusCode: 0, msg: error.localizedDescription)
            return .failure(self.error!)
        }
    }
    
    func updateKlasses(klasses: [String]) async -> Result<SSBUserResponse, NetworkError> {
        do {
            let _result: SSBUserResponse = try await networkManager.fetch(from: UpdateKlassesEndpoint(klasses: klasses))
            
            return .success(_result)
        } catch let networkError as NetworkError {
            self.error = networkError
            return .failure(self.error!)
        } catch(let error) {
            self.error = .unknownError(statusCode: 0, msg: error.localizedDescription)
            return .failure(self.error!)
        }
    }
}
