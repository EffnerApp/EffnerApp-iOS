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
            cache: timetablesCache,
            navigationTitle: "Stundenplan",
            errorTitle: "Kein Stundenplan verfügbar",
            errorDescription: "Der Stundenplan konnte nicht geladen werden. Bitte versuche es später erneut.",
            useScrollViewReader: false,
            content: { cache in
                if let timetable = cache.cachedTimetableResponse?.data.first {
                    let maxLessons = getMaxLessons(from: timetable)
                    
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
                            
                            // Stundenplan Grid - nur bis zur maximalen Stundenanzahl
                            ForEach(0..<maxLessons, id: \.self) { lessonIndex in
                                HStack(spacing: 0) {
                                    // Fächer für jeden Wochentag
                                    ForEach(0..<5, id: \.self) { dayIndex in
                                        if dayIndex < timetable.lessons.count,
                                           lessonIndex < timetable.lessons[dayIndex].count {
                                            let subject = timetable.lessons[dayIndex][lessonIndex]
                                            LessonCell(
                                                subject: subject,
                                                color: getColor(for: subject, meta: timetable.meta)
                                            )
                                        } else {
                                            LessonCell(subject: "", color: .clear)
                                        }
                                    }
                                }
                                
                                if lessonIndex < maxLessons - 1 {
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
    
    // Hilfsfunktion um die maximale Anzahl nicht-leerer Stunden zu finden
    private func getMaxLessons(from timetable: Timetable) -> Int {
        var maxLessons = 0
        
        for day in timetable.lessons {
            // Finde die letzte nicht-leere Stunde für diesen Tag
            for (index, subject) in day.enumerated().reversed() {
                if !subject.isEmpty {
                    maxLessons = max(maxLessons, index + 1)
                    break
                }
            }
        }
        
        return maxLessons
    }
    
    // Hilfsfunktion um die Farbe für ein Fach zu finden
    private func getColor(for subject: String, meta: [SubjectMeta]) -> Color {
        guard !subject.isEmpty else { return .clear }
        
        if let subjectMeta = meta.first(where: { $0.subject == subject }) {
            return Color(hex: subjectMeta.color) ?? .blue
        }
        return .blue
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
}
