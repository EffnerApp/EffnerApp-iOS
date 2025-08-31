//
//  Toolbar.swift
//  EffnerApp
//
//  Created by Luis Bros on 31.08.25.
//
import SwiftUI

struct ToolbarComponent: ToolbarContent {
    @State private var selectedClass: String = UserSession.shared.user?.classA ?? "1a"
    @State private var isDropdownVisible: Bool = false

    var body: some ToolbarContent {
        ToolbarItemGroup {
            Menu {
                VStack {
                    ForEach(ClassesCache.shared.cachedClasses, id: \ .self) { className in
                        Button(action: {
                            selectedClass = className
                            UserSession.shared.user?.classA = className
                        }) {
                            if selectedClass == className {
                                Image(systemName: "checkmark")
                            }
                            Text(className)
                        }
                        .id(className) // Set the ID for scrolling
                    }
                }
            } label: {
                Text(selectedClass)
                    .font(.title)
            }
            
            Button(action: {
                UserSession.shared.logout()
            }) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
            }
        }
    }
}

private struct Toolbar_Preview: View {
    init() {
        ClassesCache.shared.cachedClasses = ["1a", "2b", "3c", "4d", "5e", "6f", "7g", "8h", "9i", "10j", "11k", "12l", "13m", "14n", "15o"]
    }

    var body: some View {
        NavigationStack {
            Text("Toolbar Preview")
                .toolbar {
                    ToolbarComponent()
                }
        }
    }
}

#Preview {
    Toolbar_Preview()
}
