//
//  HomeView.swift
//  EffnerApp
//
//  Created by Luis Bros on 21.07.25.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            Group {
                Text("Home View")
            }
            .navigationTitle("Home")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarComponent()
            }
        }
    }
        
}

#Preview {
    HomeView()
}
