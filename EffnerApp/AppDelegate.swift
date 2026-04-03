//
//  AppDelegate.swift
//  EffnerApp
//
//  Created by Luis Bros on 27.12.25.
//

import UIKit
import UserNotifications
import OSLog

class AppDelegate: NSObject, UIApplicationDelegate {
    private static let logger = Log.notifications
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions:[UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        //requestNotificationPermission()
        UNUserNotificationCenter.current().setBadgeCount(0)
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Self.logger.info("Successfully registered for notifications.")
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        Self.logger.debug("Device token: \(token, privacy: .private)")
        
        NotificationService.shared.deviceToken = token
        
        Task {
            await updateNotificationUser()
        }
    }
    
    func updateNotificationUser() async {
        let result = await NotificationService.shared.updateDeviceToken()
        switch result {
        case .success(let response):
            Self.logger.info("Notification user updated successfully.")
            Self.logger.debug("Notification update response: \(String(describing: response), privacy: .private)")
        case .failure(let error):
            Self.logger.error("Failed to update notification user: \(error.localizedDescription)")
        }
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        Self.logger.error("Failed to register for notifications: \(error.localizedDescription)")
    }
    
    func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                Self.logger.error("Permission error: \(error.localizedDescription)")
            }
            
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                Self.logger.info("User denied notifications.")
            }
        }
    }
    
    // Handle push notification when the app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        Self.logger.debug("Will present notification: \(notification.request.content.userInfo, privacy: .private)")
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification tap/response
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle the notification and perform necessary actions
        Self.logger.debug("Notification received with identifier: \(response.notification.request.identifier)")
        Self.logger.debug("Notification content: \(response.notification.request.content.userInfo, privacy: .private)")
        completionHandler()
    }
    
    // Handle receipt of remote notification while the app is in the background
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Handle the received remote notification here

        // Print the notification payload
        Self.logger.debug("Received remote notification: \(userInfo, privacy: .private)")

        // Process the notification content
        if let aps = userInfo["aps"] as? [String: Any], let alert = aps["alert"] as? String {
            // Extract information from the notification payload
            Self.logger.debug("Notification message: \(alert)")
        }

        // Indicate the result of the background fetch to the system
        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    
}
