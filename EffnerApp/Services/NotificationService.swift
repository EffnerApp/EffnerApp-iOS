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
    
    @Published var isEnabled: Bool = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var deviceToken: String? = nil
    
    private init() {
        Task {
            await checkAuthorizationStatus()
        }
    }
    
    /// Überprüft den aktuellen Autorisierungsstatus
    func checkAuthorizationStatus() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        
        authorizationStatus = settings.authorizationStatus
        isEnabled = settings.authorizationStatus == .authorized
    }
    
    /// Fordert die Benachrichtigungsberechtigung an (wenn noch nicht geschehen)
    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            
            if granted {
                // Registriere für Remote Notifications
                UIApplication.shared.registerForRemoteNotifications()
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
        case .notDetermined:
            // Noch nicht gefragt - frage nach Berechtigung
            return await requestPermission()
            
        case .authorized:
            // Bereits autorisiert
            isEnabled = true
            return true
            
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
        isEnabled = false
        // Hinweis: Man kann programmatisch keine Berechtigung entziehen,
        // aber wir können den Status lokal speichern
    }
    
    /// Öffnet die Einstellungen der App, damit der User Berechtigungen ändern kann
    func openAppSettings() {
        if let appSettings = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(appSettings) {
                UIApplication.shared.open(appSettings)
            }
        }
    }
}
