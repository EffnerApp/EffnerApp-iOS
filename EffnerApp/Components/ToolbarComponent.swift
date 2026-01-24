//
//  Toolbar.swift
//  EffnerApp
//
//  Created by Luis Bros on 31.08.25.
//
import SwiftUI

struct ToolbarComponent: ToolbarContent {
    @EnvironmentObject var session: UserSession
    @EnvironmentObject var classesCache: ClassesCache
    @State private var isDropdownVisible: Bool = false
    @State private var isSettingsPresented: Bool = false
    
    init(isPreview: Bool = false) {
        if isPreview {
            ClassesCache.shared.saveClasses(["1a", "2b", "3c", "4d", "5e", "6f", "7g", "8h", "9i", "10j", "11k", "12l", "13m", "14n", "15o"])
        }
    }

    var body: some ToolbarContent {
        ToolbarItemGroup {
            if let userKlasses = session.user?.klasses, userKlasses.count > 1 {
                Menu {
                    // Show selected classes first
                    Section(header: Text("Meine Klassen")) {
                        ForEach(userKlasses, id: \.self) { className in
                            Button(action: {
                                session.setPrimaryClass(className)
                            }) {
                                if session.user?.primaryClass == className {
                                    Image(systemName: "checkmark")
                                }
                                Text(className)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(session.user?.primaryClass ?? "1a")
                            .font(.title)
                        if let userKlasses = session.user?.klasses, userKlasses.count > 1 {
                            Text("(+\(userKlasses.count - 1))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Button(action: {
                isSettingsPresented = true
            }) {
                Image(systemName: "gearshape")
            }
            .sheet(isPresented: $isSettingsPresented) {
                SettingsView()
            }
        }
    }
}


#Preview {
    NavigationStack {
        Text("Toolbar Preview")
            .toolbar {
                ToolbarComponent(isPreview: true)
            }
    }
    .environmentObject(UserSession.shared)
    .environmentObject(ClassesCache.shared)
}
