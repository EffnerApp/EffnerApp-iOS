//
//  ClassSelectionView.swift
//  EffnerApp
//
//  Created by Luis Bros on 24.01.26.
//

import SwiftUI

struct ClassSelectionView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var session: UserSession
    @EnvironmentObject var classesCache: ClassesCache
    
    @State private var selectedClasses: [String] = []
    @State private var extraordinaryClasses: [String] = []
    @State private var viewId = UUID() // Stable ID to prevent dismissal
    
    var body: some View {
        List {
            Section {
                Text("Du kannst mehrere Klassen auswählen, um Vertretungen und andere Informationen für alle deine Klassen zu sehen.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .listRowBackground(Color.clear)
            }
            
            if !extraordinaryClasses.isEmpty {
                Section {
                    ForEach(extraordinaryClasses, id: \.self) { className in
                        Button(action: {
                            toggleClassSelection(className)
                        }) {
                            HStack {
                                Text(className)
                                    .foregroundColor(.primary)
                                Spacer()
                                if selectedClasses.contains(className) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Besondere Klassen (Nicht unterstützt)")
                }
            }
            
            Section {
                ForEach(classesCache.cachedClasses, id: \.self) { className in
                    Button(action: {
                        toggleClassSelection(className)
                    }) {
                        HStack {
                            Text(className)
                                .foregroundColor(.primary)
                            Spacer()
                            if selectedClasses.contains(className) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
            } header: {
                Text("Wähle deine Klassen")
            }
        }
        .navigationTitle("Klassen auswählen")
        .navigationBarTitleDisplayMode(.inline)
        .id(viewId) // Prevents view from being dismissed when parent re-renders
        .onAppear {
            // Initialize with current selection
            if let userKlasses = session.user?.klasses, !userKlasses.isEmpty {
                selectedClasses = userKlasses
            }
            updateExtraordinaryClasses()
        }
        .onChange(of: classesCache.cachedClasses) {
            updateExtraordinaryClasses()
        }
        .onDisappear {
            // Trigger final update to refresh caches when leaving the view
            session.updateUserKlasses(selectedClasses)
        }
    }
    
    private func updateExtraordinaryClasses() {
        guard !classesCache.cachedClasses.isEmpty else { return }
        guard extraordinaryClasses.isEmpty else { return }
        let serverClasses = Set(classesCache.cachedClasses)
        let userKlasses = session.user?.klasses ?? []
        var seen = Set<String>()
        extraordinaryClasses = userKlasses.filter { !serverClasses.contains($0) && seen.insert($0).inserted }
    }
    
    private func toggleClassSelection(_ className: String) {
        if let index = selectedClasses.firstIndex(of: className) {
            // Class is already selected, remove it, but only if there are more than one selected
            if selectedClasses.count > 1 {
                selectedClasses.remove(at: index)
            }
        } else {
            // Class is not selected, add it at the end
            selectedClasses.append(className)
        }
    }
}

#Preview {
    NavigationStack {
        ClassSelectionView()
            .environmentObject(UserSession.shared)
            .environmentObject(ClassesCache.shared)
    }
}
