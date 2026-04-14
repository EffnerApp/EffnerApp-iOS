//
//  HomeNotificationPromptView.swift
//  EffnerApp
//
//  Created by Luis Bros on 14.04.26.
//

import SwiftUI

struct HomeNotificationPromptView: View {
    @StateObject private var notificationService = NotificationService.shared

    @State private var showingPermissionAlert = false
    @State private var isTogglingNotifications = false

    var body: some View {
        BaseContentView(
            caches: [],
            navigationTitle: "Benachrichtigungen",
            errorTitle: "Nicht verfugbar",
            errorDescription: "Die Benachrichtigungseinstellungen konnten nicht geladen werden.",
            isModal: true,
            content: { _ in
                VStack(spacing: 50) {
                    Spacer(minLength: 0)

                    Text("Benachrichtigungen aktivieren?")
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.black)
                        .padding(.horizontal, 28)

                    Image(systemName: "bell.badge.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 120)
                        .foregroundStyle(.tint)
                        .symbolRenderingMode(.hierarchical)

                    VStack(spacing: 30) {
                        Text("Mochtest du Push-Benachrichtigungen aktivieren, damit du bei neuen Vertretungen direkt informiert wirst?")
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.black)
                            .padding(.horizontal, 34)

                        Toggle(isOn: Binding(
                            get: { notificationService.isEnabled },
                            set: { newValue in
                                Task {
                                    await handleNotificationToggle(newValue)
                                }
                            }
                        )) {
                            Label("Push-Benachrichtigungen", systemImage: "bell.fill")
                                .foregroundStyle(.black)
                        }
                        .disabled(isTogglingNotifications)
                        .padding(.vertical, 22)
                        .padding(.horizontal, 18)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
                        .padding(.horizontal, 28)
                    }

                    Spacer(minLength: 32)
                }
                .padding(.top, 0)
                .padding(.bottom, 28)
                .alert("Benachrichtigungen aktivieren", isPresented: $showingPermissionAlert) {
                    Button("Abbrechen", role: .cancel) {
                        Task {
                            await notificationService.checkAuthorizationStatus()
                        }
                    }
                    Button("Einstellungen offnen") {
                        notificationService.openAppSettings()
                    }
                } message: {
                    Text("Bitte erlaube Benachrichtigungen in den App-Einstellungen, um diese Funktion zu nutzen.")
                }
            },
            skeletonView: {
                ProgressView()
            }
        )
        .task {
            await notificationService.checkAuthorizationStatus()
        }
    }

    private func handleNotificationToggle(_ newValue: Bool) async {
        isTogglingNotifications = true
        defer { isTogglingNotifications = false }

        if newValue {
            let success = await notificationService.enableNotifications()
            if !success && notificationService.authorizationStatus == .denied {
                showingPermissionAlert = true
            }
        } else {
            notificationService.disableNotifications()
        }
    }
}

#Preview {
    HomeNotificationPromptView()
}
