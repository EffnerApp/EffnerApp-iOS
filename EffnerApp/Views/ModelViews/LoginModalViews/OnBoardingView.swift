//
//  OnBoardingView.swift
//  EffnerApp
//
//  Created by Luis Bros on 02.04.26.
//

import SwiftUI

struct OnBoardingPage: Identifiable {
    let id = UUID()
    let title: String
    let imageName: String
    let description: String
}

struct OnBoardingView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentPage = 0
    
    private let pages: [OnBoardingPage] = [
        OnBoardingPage(
            title: "Willkommen bei Effner",
            imageName: "graduationcap.fill",
            description: "Deine Schul-App für den Alltag am Josef-Effner-Gymnasium. Alles Wichtige auf einen Blick."
        ),
        OnBoardingPage(
            title: "Stundenplan & Vertretungen",
            imageName: "calendar.badge.clock",
            description: "Sieh deinen aktuellen Stundenplan und erfahre sofort, wenn sich etwas ändert."
        ),
        OnBoardingPage(
            title: "Prüfungen & Termine",
            imageName: "pencil.and.list.clipboard",
            description: "Behalte alle anstehenden Prüfungen und wichtigen Termine im Überblick."
        ),
        OnBoardingPage(
            title: "Benachrichtigungen",
            imageName: "bell.badge.fill",
            description: "Erhalte Push-Benachrichtigungen bei neuen Vertretungen und wichtigen Änderungen."
        )
    ]
    
    var body: some View {
        BaseContentView(
            caches: [],
            navigationTitle: "Willkommen",
            errorTitle: "Nicht verfügbar",
            errorDescription: "Das Onboarding konnte nicht geladen werden.",
            isModal: true,
            content: { _ in
                VStack(spacing: 0) {
                    TabView(selection: $currentPage) {
                        ForEach(Array(pages.enumerated()), id: \.element.id) { index, page in
                            VStack(spacing: 32) {
                                Spacer()
                                
                                // Überschrift
                                Text(page.title)
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                                
                                // Bild
                                Image(systemName: page.imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 120)
                                    .foregroundStyle(.tint)
                                    .symbolRenderingMode(.hierarchical)
                                
                                // Text
                                Text(page.description)
                                    .font(.body)
                                    .multilineTextAlignment(.center)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 32)
                                
                                Spacer()
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    
                    // Page Indicator & Button
                    VStack(spacing: 20) {
                        // Custom Page Indicator
                        HStack(spacing: 8) {
                            ForEach(0..<pages.count, id: \.self) { index in
                                Circle()
                                    .fill(index == currentPage ? Color.accentColor : Color.secondary.opacity(0.3))
                                    .frame(width: 8, height: 8)
                                    .animation(.easeInOut(duration: 0.2), value: currentPage)
                            }
                        }
                        
                        // Weiter / Fertig Button
                        Button(action: {
                            withAnimation {
                                if currentPage < pages.count - 1 {
                                    currentPage += 1
                                } else {
                                    dismiss()
                                }
                            }
                        }) {
                            Text(currentPage == pages.count - 1 ? "Los geht's" : "Weiter")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.horizontal, 32)
                    }
                    .padding(.bottom, 40)
                }
            },
            skeletonView: {
                ProgressView()
            }
        )
    }
}

#Preview {
    OnBoardingView()
}
