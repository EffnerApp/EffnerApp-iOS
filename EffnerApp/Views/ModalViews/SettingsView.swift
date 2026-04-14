//
//  SettingsView.swift
//  EffnerApp
//
//  Created by Luis Bros on 07.12.25.
//

import SwiftUI
import OSLog

struct SettingsView: View {
    private static let logger = Log.settings
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var session: UserSession
    @EnvironmentObject var classesCache: ClassesCache
    @StateObject private var notificationService = NotificationService.shared
    
    init(isPreview: Bool = false) {
        if isPreview {
            ClassesCache.shared.saveClasses(["1a", "2b", "3c", "4d", "5e", "6f", "7g", "8h", "9i", "10j", "11k", "12l"])
        }
    }
    
    @State private var showingLogoutAlert = false
    @State private var showingPermissionAlert = false
    @State private var isTogglingNotifications = false
    
    var selectedClassesText: String {
        let klasses = session.user?.klasses ?? []
        if klasses.isEmpty {
            return "Keine Klasse ausgewählt"
        } else if klasses.count == 1 {
            return klasses[0]
        } else {
            return "\(klasses.count) Klassen"
        }
    }
    
    var appVersion: String {
        AppVersionProvider.displayString
    }
    
    var body: some View {
        BaseContentView(
            caches: [classesCache],
            navigationTitle: "Einstellungen",
            errorTitle: "Einstellungen nicht verfügbar",
            errorDescription: "Die Einstellungen konnten nicht geladen werden. Bitte versuche es später erneut.",
            isModal: true,
            content: { cache in
                List {
                    // Einstellungen Section
                    Section {
                        // Push Benachrichtigungen Toggle
                        Toggle(isOn: Binding(
                            get: { notificationService.isEnabled },
                            set: { newValue in
                                Task {
                                    await handleNotificationToggle(newValue)
                                }
                            }
                        )) {
                            Label("Push-Benachrichtigungen", systemImage: "bell.fill")
                        }
                        .disabled(isTogglingNotifications)
                        
                        // Klassen-Auswahl (Multi-Select)
                        NavigationLink(destination: ClassSelectionView()) {
                            HStack {
                                Label("Klassen", systemImage: "person.3.fill")
                                Spacer()
                                Text(selectedClassesText)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        
                        
                        // Abmelden Button
                        Button(role: .destructive, action: {
                            showingLogoutAlert = true
                        }) {
                            Label("Abmelden", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } header: {
                        Text("Einstellungen")
                    }
                    
                    // Über Section
                    Section {
                        Link(destination: URL(string: "mailto:support@effner.app")!) {
                            Label("Feedback", systemImage: "envelope")
                        }
                        
                        Link(destination: URL(string: "https://effner.app/privacy")!) {
                            Label("Datenschutzerklärung", systemImage: "hand.raised.fill")
                        }
                        
                        Link(destination: URL(string: "https://effner.app/imprint")!) {
                            Label("Impressum", systemImage: "doc.text.fill")
                        }
                        
                        Link(destination: URL(string: "https://effner.app/status")!) {
                            Label("Status", systemImage: "checkmark.circle.fill")
                        }
                    } header: {
                        Text("Über")
                    }
                    
                    // App Version
                    Section {
                        HStack {
                            Spacer()
                            VStack {
                                Text(appVersion)
                                Text("Luis Bros - Softwareentwicklung")
                            }
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                    }
                }
                .alert("Abmelden", isPresented: $showingLogoutAlert) {
                    Button("Abbrechen", role: .cancel) { }
                    Button("Abmelden", role: .destructive) {
                        Task {
                            await session.logout()
                            dismiss()
                        }
                    }
                } message: {
                    Text("Möchtest du dich wirklich abmelden?")
                }
                .alert("Benachrichtigungen aktivieren", isPresented: $showingPermissionAlert) {
                    Button("Abbrechen", role: .cancel) {
                        // Status wiederherstellen
                        Task {
                            await notificationService.checkAuthorizationStatus()
                        }
                    }
                    Button("Einstellungen öffnen") {
                        notificationService.openAppSettings()
                    }
                } message: {
                    Text("Bitte erlaube Benachrichtigungen in den App-Einstellungen, um diese Funktion zu nutzen.")
                }
            },
            skeletonView: {
                // Für Settings brauchen wir kein Skeleton, da sie immer geladen sind
                ProgressView()
            }
        )
        .task {
            // Status beim Öffnen der View aktualisieren
            await notificationService.checkAuthorizationStatus()
        }
    }
    
    /// Behandelt das Umschalten des Benachrichtigungs-Toggle
    private func handleNotificationToggle(_ newValue: Bool) async {
        isTogglingNotifications = true
        defer { isTogglingNotifications = false }
        
        if newValue {
            // User möchte Benachrichtigungen aktivieren
            let success = await notificationService.enableNotifications()
            
            if success {
                // Benachrichtigungen erfolgreich aktiviert
                Self.logger.info("Notifications enabled.")
            }
            
            if !success && notificationService.authorizationStatus == .denied {
                // Berechtigung wurde verweigert - zeige Alert
                showingPermissionAlert = true
            }
        } else {
            // User möchte Benachrichtigungen deaktivieren
            notificationService.disableNotifications()
        }
        
        do {
            try await Task.sleep(for: .seconds(5))
        } catch {
            Self.logger.debug("Sleep interrupted: \(error)")
        }
            
        
    }
}

#Preview {
    SettingsView(isPreview: true)
        .environmentObject(UserSession.shared)
        .environmentObject(ClassesCache.shared)
}