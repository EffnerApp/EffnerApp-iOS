//
//  ContentView.swift
//  EffnerApp
//
//  Created by Luis Bros on 29.06.25.
//

import SwiftUI

struct FourthView: View {
    var body: some View {
        NavigationStack {
            Group {
                Text("Fourth View")
            }
            .navigationTitle("Fourth")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarComponent()
            }
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack(spacing: 0) {
            TabView {
                HomeView()
                    .tabItem {
                        Image(systemName: "house")
                        Text("Home")
                    }
                SubstitutionsView()
                    .tabItem {
                        Image(systemName: "arrow.trianglehead.branch")
                        Text("Vertretungen")
                    }
                ExamsView()
                    .tabItem {
                        Image(systemName: "graduationcap")
                        Text("Klausuren")
                    }
                TimetableView()
                    .tabItem {
                        Image(systemName: "calendar.day.timeline.right")
                        Text("Stundenplan")
                    }
            }
        }
    }
}

#Preview {
    ContentView()
}
