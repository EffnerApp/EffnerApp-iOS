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
    @StateObject private var timetables = TimetablesCache.shared
    @StateObject private var config = ConfigCache.shared
    @StateObject private var documents = DocumentsCache.shared
    
    var body: some Scene {
        WindowGroup {
            if let user = session.user, user.isAuthorized {
                ContentView()
                    .environmentObject(session)
                    .environmentObject(exams)
                    .environmentObject(classes)
                    .environmentObject(substitutions)
                    .environmentObject(timetables)
                    .transition(.slide)
            } else {
                LoginView()
                    .environmentObject(session)
                    .environmentObject(exams)
                    .environmentObject(classes)
                    .environmentObject(substitutions)
                    .environmentObject(timetables)
            }
        }
    }
        
}
