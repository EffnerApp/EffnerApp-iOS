//
//  HomeSkeletonView.swift
//  EffnerApp
//
//  Created by Luis Bros on 02.12.25.
//

import SwiftUI

// MARK: - Home Skeleton View
struct HomeSkeletonView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Timeline Skeleton
                VStack(alignment: .leading, spacing: 12) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.gray.opacity(0.2))
                        .frame(width: 80, height: 20)
                    
                    TimelineSkeletonView()
                }
                .padding(.horizontal)
                
                // Bento Grid Skeleton
                VStack(spacing: 12) {
                    // Wichtige Infos Skeleton
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.gray.opacity(0.2))
                        .frame(height: 120)
                    
                    // Grid Skeleton
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 12),
                        GridItem(.flexible(), spacing: 12)
                    ], spacing: 12) {
                        ForEach(0..<4) { _ in
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.gray.opacity(0.2))
                                .frame(height: 100)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

// MARK: - Timeline Skeleton View
struct TimelineSkeletonView: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(0..<6) { _ in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.gray.opacity(0.2))
                        .frame(width: 100, height: 80)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomeSkeletonView()
    }
}
