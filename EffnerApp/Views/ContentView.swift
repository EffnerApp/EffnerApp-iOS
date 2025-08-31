//
//  ContentView.swift
//  EffnerApp
//
//  Created by Luis Bros on 29.06.25.
//

import SwiftUI

struct SecondView: View {
    var body: some View {
        NavigationStack {
            HStack {
                Text("Second View")
            }
            .navigationTitle("Second")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarComponent()
            }
        }
    }
}

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
                SecondView()
                    .tabItem {
                        Image(systemName: "2.circle")
                        Text("Second")
                    }
                ExamsView()
                    .tabItem {
                        Image(systemName: "graduationcap")
                        Text("Klausuren")
                    }
                FourthView()
                    .tabItem {
                        Image(systemName: "4.circle")
                        Text("Fourth")
                    }
            }
        }
    }
}

#Preview {
    ContentView()
}
