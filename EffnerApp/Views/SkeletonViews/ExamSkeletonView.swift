//
//  ExamSkeletonView.swift
//  EffnerApp
//
//  Created by Luis Bros on 31.08.25.
//
import SwiftUI

struct ExamSkeletonView: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(isAnimating ? 0.3 : 0.1))
                .frame(width: 120, height: 18)
                .animation(Animation.linear(duration: 1).repeatForever(autoreverses: true), value: isAnimating)
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(isAnimating ? 0.2 : 0.1))
                    .frame(width: 80, height: 14)
                    .animation(Animation.linear(duration: 1).repeatForever(autoreverses: true), value: isAnimating)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(isAnimating ? 0.2 : 0.1))
                    .frame(width: 80, height: 14)
                    .animation(Animation.linear(duration: 1).repeatForever(autoreverses: true), value: isAnimating)
            }
        }
        .padding(.vertical, 8)
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    ExamSkeletonView()
}
