//
//  SettingsView.swift
//  EffnerApp
//
//  Created by Luis Bros on 07.12.25.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var session: UserSession
    @EnvironmentObject var classesCache: ClassesCache
    @StateObject private var notificationService = NotificationService.shared
    
    init(isPreview: Bool = false) {
        if isPreview {
            ClassesCache.shared.saveClasses(["1a", "2b", "3c", "4d", "5e", "6f", "7g", "8h", "9i", "10j", "11k", "12l", "13m", "14n", "15o"])
        }
    }
    
    @State private var showingLogoutAlert = false
    @State private var showingPermissionAlert = false
    @State private var isTogglingNotifications = false
    
    var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "Version \(version) (\(build))"
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
                        
                        // Klassen-Auswahl
                        Picker(selection: Binding(
                            get: { session.user?.klass ?? "" },
                            set: { newValue in
                                session.updateUserKlass(newValue)
                            }
                        )) {
                            ForEach(classesCache.cachedClasses, id: \.self) { className in
                                Text(className).tag(className)
                            }
                            Text("test").tag("test")
                        } label: {
                            Label("Klasse", systemImage: "person.3.fill")
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
                        Link(destination: URL(string: "https://example.com/feedback")!) {
                            Label("Feedback", systemImage: "envelope")
                        }
                        
                        Link(destination: URL(string: "https://example.com/datenschutz")!) {
                            Label("Datenschutzerklärung", systemImage: "hand.raised.fill")
                        }
                        
                        Link(destination: URL(string: "https://example.com/impressum")!) {
                            Label("Impressum", systemImage: "doc.text.fill")
                        }
                        
                        Link(destination: URL(string: "https://example.com/status")!) {
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
                        session.logout()
                        dismiss()
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
                print("✅ Benachrichtigungen erfolgreich aktiviert")
            }
            
            if !success && notificationService.authorizationStatus == .denied {
                // Berechtigung wurde verweigert - zeige Alert
                showingPermissionAlert = true
            }
        } else {
            // User möchte Benachrichtigungen deaktivieren
            notificationService.disableNotifications()
        }
    }
}

#Preview {
    SettingsView(isPreview: true)
        .environmentObject(UserSession.shared)
        .environmentObject(ClassesCache.shared)
}
