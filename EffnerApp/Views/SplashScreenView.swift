//
//  SplashScreenView.swift
//  EffnerApp
//
//  Created by Luis Bros on 02.04.26.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var isAnimating = false
    @Binding var isFinished: Bool

    var body: some View {
        GeometryReader { geometry in
            let screenHeight = geometry.size.height
            // Matches storyboard constraint: label.centerY = view.bottom * 1/3 + 1
            let titleCenterY = screenHeight / 3.0 + 1

            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                // "EffnerApp" title — positioned at 1/3 from top
                Text("EffnerApp")
                    .font(.system(size: 36, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .position(x: geometry.size.width / 2, y: titleCenterY)

                // Logo — centered on screen
                Image("Logo")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 200, height: 200)
                    .position(x: geometry.size.width / 2, y: screenHeight / 2)
            }
        }
        .ignoresSafeArea()
        .scaleEffect(isAnimating ? 8 : 1)
        .opacity(isAnimating ? 0 : 1)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.easeIn(duration: 0.5)) {
                    isAnimating = true
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
                isFinished = true
            }
        }
    }
}
