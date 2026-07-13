//
//  EffnerAppApp.swift
//  EffnerApp
//
//  Created by Luis Bros on 29.06.25.
//

import SwiftUI

@main
struct EffnerAppApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var session = UserSession.shared
    @StateObject private var classes = ClassesCache.shared
    @StateObject private var exams = ExamsCache.shared
    @StateObject private var substitutions = SubstitutionsCache.shared
    @StateObject private var timetables = TimetablesCache.shared
    @StateObject private var holidays = HolidaysCache.shared
    @StateObject private var notifications = NotificationService.shared
    
    @State private var splashFinished = false
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                Group {
                    if let user = session.user, user.isAuthorized {
                        // User hat eine Session und ist autorisiert → ContentView
                        ContentView()
                            .environmentObject(session)
                            .environmentObject(classes)
                            .environmentObject(exams)
                            .environmentObject(substitutions)
                            .environmentObject(timetables)
                            .environmentObject(holidays)
                            .environmentObject(notifications)
                    } else {
                        // Keine Session oder nicht autorisiert → LoginView
                        LoginView()
                            .environmentObject(session)
                            .environmentObject(classes)
                            .environmentObject(exams)
                            .environmentObject(substitutions)
                            .environmentObject(timetables)
                    }
                }
                .animation(.easeIn(duration: 0.3), value: session.user?.isAuthorized)

                if !splashFinished {
                    SplashScreenView(isFinished: $splashFinished)
                        .ignoresSafeArea()
                }
            }
        }
    }
        
}
