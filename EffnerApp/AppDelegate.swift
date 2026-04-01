//
//  AppDelegate.swift
//  EffnerApp
//
//  Created by Luis Bros on 27.12.25.
//

import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    
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
        print("Successfully registered for notifications! Token: \(deviceToken)")
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token joined: \(token)")
        
        NotificationService.shared.deviceToken = token
        
        Task {
            await updateNotificationUser()
        }
    }
    
    func updateNotificationUser() async {
        let result = await NotificationService.shared.updateDeviceToken()
        switch result {
        case .success(let response):
            print("Notification user updated successfully.")
            print("Notification update Response: \(response)")
        case .failure(let error):
            print("Failed to update notification user: \(error.localizedDescription)")
        }
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        print("Failed to register for notifications: \(error.localizedDescription)")
    }
    
    func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Permission Error: \(error.localizedDescription)")
            }
            
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("User denied notifications.")
            }
        }
    }
    
    // Handle push notification when the app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("Will present notification: \(notification.request.content.userInfo)")
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification tap/response
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle the notification and perform necessary actions
        print("Notification received with identifier: \(response.notification.request.identifier)")
        print("Notification content: \(response.notification.request.content.userInfo)")
        completionHandler()
    }
    
    // Handle receipt of remote notification while the app is in the background
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Handle the received remote notification here

        // Print the notification payload
        print("Received remote notification: \(userInfo)")

        // Process the notification content
        if let aps = userInfo["aps"] as? [String: Any], let alert = aps["alert"] as? String {
            // Extract information from the notification payload
            print("Notification message: \(alert)")
        }

        // Indicate the result of the background fetch to the system
        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    
}
