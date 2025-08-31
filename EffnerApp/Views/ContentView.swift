//
//  ContentView.swift
//  EffnerApp
//
//  Created by Luis Bros on 29.06.25.
//

import SwiftUI

struct SecondView: View {
    var body: some View {
        VStack {
            Text("Second View")
                .font(.largeTitle)
        }
    }
}

struct ThirdView: View {
    var body: some View {
        VStack {
            Text("Third View")
                .font(.largeTitle)
        }
    }
}

struct FourthView: View {
    var body: some View {
        VStack {
            Text("Fourth View")
                .font(.largeTitle)
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
                        Text("Exams")
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
