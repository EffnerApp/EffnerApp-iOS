//
//  EffnerAppApp.swift
//  EffnerApp
//
//  Created by Luis Bros on 29.06.25.
//

import SwiftUI

@main
struct EffnerAppApp: App {
    @State private var session = UserSession.shared
    @State private var exams = ExamsCache.shared
    @State private var classes = ClassesCache.shared
    
    var body: some Scene {
        WindowGroup {
            if let user = session.user, user.isAuthorized {
                ContentView()
                    .transition(.slide)
            } else {
                LoginView()
            }
        }
    }
        
}
