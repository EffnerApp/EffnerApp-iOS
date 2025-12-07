//
//  TimelineBarComponent.swift
//  EffnerApp
//
//  Created by Luis Bros on 02.12.25.
//

import SwiftUI

// MARK: - Timeline Bar View
struct TimelineBarComponent: View {
    let timetable: Timetable?
    let schedule: [Array<Int>?]?
    let substitutions: [Substitution]?
    let currentTime: Date
    var forcedDayIndex: Int? = nil
    
    @State private var selectedDay: Int = Calendar.current.component(.weekday, from: Date())
    
    var body: some View {
        if let timetable = timetable {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 3) {
                    ForEach(Array(todayLessons.enumerated()), id: \.offset) { index, subject in
                        TimelineSubjectCard(
                            subject: subject,
                            period: index + 1,
                            color: subjectColor(for: subject, in: timetable),
                            hasSubstitution: hasSubstitutionForPeriod(index + 1),
                            timeRange: timeRangeForPeriod(index),
                            isCurrent: isCurrentLesson(period: index)
                        )
                    }
                }
            }
            .contentMargins(.horizontal, 12)
        } else {
            TimelineSkeletonView()
        }
    }
    
    private var todayLessons: [String] {
        guard let timetable = timetable else { return [] }
        
        // Wenn ein forcedDayIndex übergeben wurde, diesen verwenden
        let dayIndex: Int
        if let forced = forcedDayIndex {
            dayIndex = forced
        } else {
            let weekday = Calendar.current.component(.weekday, from: Date())
            
            // Umrechnung: Swift weekday (1=Sonntag, 2=Montag, ..., 7=Samstag)
            // zu Stundenplan dayIndex (0=Montag, 1=Dienstag, ..., 4=Freitag)
            switch weekday {
            case 2: dayIndex = 0 // Montag
            case 3: dayIndex = 1 // Dienstag
            case 4: dayIndex = 2 // Mittwoch
            case 5: dayIndex = 3 // Donnerstag
            case 6: dayIndex = 4 // Freitag
            default: dayIndex = -1 // Samstag (7) und Sonntag (1) haben keinen Unterricht
            }
        }
        
        guard dayIndex >= 0 && dayIndex < timetable.lessons.count else { return [] }
        
        return timetable.lessons[dayIndex].filter { !$0.isEmpty }
    }
    
    private func subjectColor(for subject: String, in timetable: Timetable) -> Color {
        guard let meta = timetable.meta.first(where: { $0.subject == subject }) else {
            return .gray
        }
        return Color(hex: meta.color) ?? .gray
    }
    
    private func hasSubstitutionForPeriod(_ period: Int) -> Bool {
        guard let substitutions = substitutions else { return false }
        return substitutions.contains { $0.period == "\(period)" }
    }
    
    private func timeRangeForPeriod(_ period: Int) -> String {
        guard let schedule = schedule else { return "" }
        
        // Der Schedule enthält Start- und Endzeiten in Paaren: [start, end, start, end, ...]
        let startIndex = period * 2
        let endIndex = startIndex + 1
        
        guard endIndex < schedule.count,
              let startTime = schedule[startIndex],
              let endTime = schedule[endIndex],
              startTime.count == 2,
              endTime.count == 2 else {
            return ""
        }
        
        let startHour = startTime[0]
        let startMin = startTime[1]
        let endHour = endTime[0]
        let endMin = endTime[1]
        
        return String(format: "%02d:%02d-%02d:%02d", startHour, startMin, endHour, endMin)
    }
    
    private func isCurrentLesson(period: Int) -> Bool {
        guard let schedule = schedule else { return false }
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentTime)
        let minute = calendar.component(.minute, from: currentTime)
        
        // Der Schedule enthält Start- und Endzeiten in Paaren: [start, end, start, end, ...]
        // period ist 0-basiert, daher: Stunde 0 = schedule[0] bis schedule[1]
        let startIndex = period * 2
        let endIndex = startIndex + 1
        
        guard endIndex < schedule.count,
              let startTime = schedule[startIndex],
              let endTime = schedule[endIndex],
              startTime.count == 2,
              endTime.count == 2 else {
            return false
        }
        
        let startHour = startTime[0]
        let startMin = startTime[1]
        let endHour = endTime[0]
        let endMin = endTime[1]
        
        let currentMinutes = hour * 60 + minute
        let startMinutes = startHour * 60 + startMin
        let endMinutes = endHour * 60 + endMin
        
        return currentMinutes >= startMinutes && currentMinutes <= endMinutes
    }
}

// MARK: - Timeline Subject Card
struct TimelineSubjectCard: View {
    let subject: String
    let period: Int
    let color: Color
    let hasSubstitution: Bool
    let timeRange: String
    let isCurrent: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            // Fachname (zentriert, ggf. durchgestrichen)
            HStack(spacing: 4) {
                Text(subject)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .strikethrough(hasSubstitution, color: .primary)
                
                if hasSubstitution {
                    Image(systemName: "door.left.hand.open")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
            .frame(maxWidth: .infinity)

            
            // Farbige Linie
            Rectangle()
                .fill(color)
                .frame(height: 3)
                .frame(maxWidth: .infinity)
            
            Text(timeRange)
                .font(.caption2)
                .foregroundStyle(.secondary)
                
        }
        .frame(width: 100)
        .padding(.horizontal, 0)
        .padding(.vertical, 10)
        .overlay(
            // Vertikale rote Linie für aktuelle Stunde
            GeometryReader { geometry in
                if isCurrent {
                    Rectangle()
                        .fill(.red)
                        .frame(width: 1)
                        .frame(height: geometry.size.height)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
            }
        )
    }
}

