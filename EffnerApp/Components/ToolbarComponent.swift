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
    
    init(isPreview: Bool = false) {
        if isPreview {
            ClassesCache.shared.saveClasses(["1a", "2b", "3c", "4d", "5e", "6f", "7g", "8h", "9i", "10j", "11k", "12l", "13m", "14n", "15o"])
        }
    }

    var body: some ToolbarContent {
        ToolbarItemGroup {
            Menu {
                VStack {
                    ForEach(ClassesCache.shared.cachedClasses, id: \.self) { className in
                        Button(action: {
                            session.updateUserKlass(className)
                        }) {
                            if session.user?.klass == className {
                                Image(systemName: "checkmark")
                            }
                            Text(className)
                        }
                        .id(className) // Set the ID for scrolling
                    }
                    Button(action: {
                        session.updateUserKlass("test")
                    }) {
                        if session.user?.klass == "test" {
                            Image(systemName: "checkmark")
                        }
                        Text("test")
                    }
                }
            } label: {
                Text(session.user?.klass ?? "1a")
                    .font(.title)
            }
            
            Button(action: {
                session.logout()
            }) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
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
