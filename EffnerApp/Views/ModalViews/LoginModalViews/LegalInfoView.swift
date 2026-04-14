//
//  LegalInfoView.swift
//  EffnerApp
//
//  Created by Luis Bros on 02.04.26.
//

import SwiftUI

struct LegalInfoView: View {
    var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "Version \(version) (\(build))"
    }
    
    var body: some View {
        BaseContentView(
            caches: [],
            navigationTitle: "Rechtliche Infos",
            errorTitle: "Nicht verfügbar",
            errorDescription: "Die Informationen konnten nicht geladen werden.",
            isModal: true,
            content: { _ in
                List {
                    // Rechtliches Section
                    Section {
                        Link(destination: URL(string: "https://effner.app/imprint")!) {
                            Label("Impressum", systemImage: "doc.text.fill")
                        }
                        
                        Link(destination: URL(string: "https://effner.app/privacy")!) {
                            Label("Datenschutzerklärung", systemImage: "hand.raised.fill")
                        }
                    } header: {
                        Text("Rechtliches")
                    }
                    
                    // Kontakt Section
                    Section {
                        Link(destination: URL(string: "mailto:support@effner.app")!) {
                            Label("Feedback", systemImage: "envelope")
                        }
                        
                        Link(destination: URL(string: "https://effner.app/status")!) {
                            Label("Status", systemImage: "checkmark.circle.fill")
                        }
                    } header: {
                        Text("Kontakt")
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
            },
            skeletonView: {
                ProgressView()
            }
        )
    }
}

#Preview {
    LegalInfoView()
}
