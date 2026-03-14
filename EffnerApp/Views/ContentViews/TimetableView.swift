//
//  TimetableView.swift
//  EffnerApp
//
//  Created by Luis Bros on 16.11.25.
//

import SwiftUI

struct TimetableView: View {
    @ObservedObject var timetablesCache = TimetablesCache.shared
    
    init(isPreview: Bool = false) {
        if isPreview {
            TimetablesCache.shared.saveTimetables(MockTimetable.mockTimetable)
        }
    }
    
    private let weekdays = ["Mo", "Di", "Mi", "Do", "Fr"]
    
    var body: some View {
        BaseContentView(
            caches: [timetablesCache],
            navigationTitle: "Stundenplan",
            errorTitle: "Kein Stundenplan verfügbar",
            errorDescription: "Der Stundenplan konnte nicht geladen werden. Bitte versuche es später erneut.",
            useScrollViewReader: false,
            content: { cache in
                if let timetable = timetablesCache.cachedResponse {
                    let visibleSlots = getVisibleSlots(from: timetable)
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            // Header mit Wochentagen
                            HStack(spacing: 0) {
                                // Wochentage
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
                            
                            // Stundenplan Grid
                            ForEach(Array(visibleSlots.enumerated()), id: \.offset) { index, slot in
                                HStack(spacing: 0) {
                                    ForEach(0..<5, id: \.self) { dayIndex in
                                        let subjects = slot.subjects(for: dayIndex)
                                        let displayText = subjects.map(\.name).joined(separator: "/")
                                        let color = subjects.first.flatMap { Color(hex: $0.color) } ?? .blue
                                        LessonCell(
                                            subject: displayText,
                                            color: displayText.isEmpty ? .clear : color
                                        )
                                    }
                                }
                                
                                if index < visibleSlots.count - 1 {
                                    Divider()
                                }
                            }
                        }
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                        .padding()
                    }
                    .scrollBounceBehavior(.basedOnSize)
                }
            },
            skeletonView: {
                TimetableSkeletonView()
            }
        )
    }
    
    // Hilfsfunktion: nur Slots anzeigen bis zum letzten Slot mit Unterricht
    private func getVisibleSlots(from timetable: TimetableResponse) -> [TimetableSlot] {
        var lastIndex = 0
        for (index, slot) in timetable.slots.enumerated() {
            if slot.hasAnySubjects {
                lastIndex = index
            }
        }
        return Array(timetable.slots.prefix(lastIndex + 1))
    }
}

// MARK: - Lesson Cell
struct LessonCell: View {
    let subject: String
    let color: Color
    
    var body: some View {
        VStack {
            if subject.isEmpty {
                Text("—")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Text(subject)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .background(subject.isEmpty ? Color(.systemGray6) : color.opacity(0.85))
        .overlay(
            Rectangle()
                .stroke(Color(.systemGray4), lineWidth: 0.5)
        )
    }
}

// MARK: - Color Extension für Hex-Support
extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}



#Preview {
    TimetableView(isPreview: true)
        .environmentObject(UserSession.shared)
        .environmentObject(ClassesCache.shared)
        .environmentObject(TimetablesCache.shared)
}
