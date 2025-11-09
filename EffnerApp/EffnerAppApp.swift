//
//  EffnerAppApp.swift
//  EffnerApp
//
//  Created by Luis Bros on 29.06.25.
//

import SwiftUI

@main
struct EffnerAppApp: App {
    @StateObject private var session = UserSession.shared
    @StateObject private var exams = ExamsCache.shared
    @StateObject private var classes = ClassesCache.shared
    @StateObject private var substitutions = SubstitutionsCache.shared
    
    var body: some Scene {
        WindowGroup {
            if let user = session.user, user.isAuthorized {
                ContentView()
                    .environmentObject(session)
                    .environmentObject(exams)
                    .environmentObject(classes)
                    .environmentObject(substitutions)
                    .transition(.slide)
            } else {
                LoginView()
                    .environmentObject(session)
                    .environmentObject(exams)
                    .environmentObject(classes)
                    .environmentObject(substitutions)
            }
        }
    }
        
}
