//
//  TimetableSkeletonView.swift
//  EffnerApp
//
//  Created by Luis Bros on 16.11.25.
//

import SwiftUI

struct TimetableSkeletonView: View {
    @State private var isAnimating = false
    
    private let weekdays = ["Mo", "Di", "Mi", "Do", "Fr"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header mit Wochentagen
                HStack(spacing: 0) {
                    ForEach(weekdays, id: \.self) { day in
                        Text(day)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(Color(.systemGray6))
                    }
                }
                .background(Color(.systemGray5))
                
                Divider()
                
                // Skeleton Grid für Stunden
                ForEach(0..<10, id: \.self) { lessonIndex in
                    HStack(spacing: 0) {
                        // Skeleton Zellen für jeden Wochentag
                        ForEach(0..<5, id: \.self) { dayIndex in
                            SkeletonLessonCell(isAnimating: isAnimating)
                        }
                    }
                    
                    if lessonIndex < 9 {
                        Divider()
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            .padding()
        }
        .scrollBounceBehavior(.basedOnSize)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Skeleton Lesson Cell
struct SkeletonLessonCell: View {
    let isAnimating: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            // Platzhalter für Fachname
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray5))
                .frame(width: 40, height: 12)
                .opacity(isAnimating ? 0.5 : 1.0)
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray5))
                .frame(width: 30, height: 12)
                .opacity(isAnimating ? 0.5 : 1.0)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .background(Color(.systemGray6))
        .overlay(
            Rectangle()
                .stroke(Color(.systemGray4), lineWidth: 0.5)
        )
    }
}

#Preview {
    NavigationStack {
        TimetableSkeletonView()
    }
}
