//
//  TimelineBarComponent.swift
//  EffnerApp
//
//  Created by Luis Bros on 02.12.25.
//

import SwiftUI

// MARK: - Timeline Bar View
struct TimelineBarComponent: View {
    @ObservedObject var timetableCache = TimetablesCache.shared
    let substitutions: [Substitution]?
    let currentTime: Date
    
    @State private var selectedDay: Int = Calendar.current.component(.weekday, from: Date())
    
    private var timetable: TimetableResponse? {
        timetableCache.cachedResponse
    }
    
    private var forcedDayIndex: Int? {
        nextAvailableDay.dayIndex
    }
    
    var body: some View {
        // Timeline Widget (nimmt volle Breite)
        GridWidget(
            icon: "clock.fill",
            title: "Timeline am \(DateFormatterUtil.formatToShortDate(nextAvailableDay.date))",
            iconColor: .blue,
            removePadding: true
        ) {
            if timetable != nil {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 3) {
                        ForEach(Array(todaySlots.enumerated()), id: \.offset) { index, slotInfo in
                            TimelineSubjectCard(
                                subject: slotInfo.displayText,
                                period: index + 1,
                                color: slotInfo.color,
                                hasSubstitution: hasSubstitutionForPeriod(index + 1),
                                timeRange: slotInfo.timeRange,
                                isCurrent: isCurrentLesson(slot: slotInfo.slot)
                            )
                        }
                    }
                }
                .contentMargins(.horizontal, 12)
            } else {
                TimelineSkeletonView()
            }
        }
    }
    
    
    // Berechnet den nächsten verfügbaren Tag mit Unterricht
    private var nextAvailableDay: (date: Date, dayIndex: Int) {
        guard let timetable = timetable else {
            return (Date(), 0)
        }
        
        let calendar = Calendar.current
        var checkDate = Date()
        
        // Maximal 7 Tage in die Zukunft schauen
        for _ in 0..<7 {
            let weekday = calendar.component(.weekday, from: checkDate)
            
            // Umrechnung: Swift weekday (1=Sonntag, 2=Montag, ..., 7=Samstag)
            // zu Stundenplan dayIndex (0=Montag, 1=Dienstag, ..., 4=Freitag)
            var dayIndex: Int
            switch weekday {
            case 2: dayIndex = 0 // Montag
            case 3: dayIndex = 1 // Dienstag
            case 4: dayIndex = 2 // Mittwoch
            case 5: dayIndex = 3 // Donnerstag
            case 6: dayIndex = 4 // Freitag
            default: dayIndex = -1 // Samstag (7) und Sonntag (1) haben keinen Unterricht
            }
            
            // Prüfen ob der Tag ein Schultag ist und Unterricht hat
            if dayIndex >= 0 {
                let hasLessons = timetable.slots.contains { !$0.subjects(for: dayIndex).isEmpty }
                if hasLessons {
                    return (checkDate, dayIndex)
                }
            }
            
            // Nächsten Tag prüfen
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: checkDate) {
                checkDate = nextDay
            }
        }
        
        // Fallback auf Montag
        return (Date(), 0)
    }

    
    /// Returns the slots that have subjects for the current day, along with display info
    private var todaySlots: [(slot: TimetableSlot, displayText: String, timeRange: String, color: Color)] {
        guard let timetable = timetable else { return [] }
        
        let dayIndex: Int
        if let forced = forcedDayIndex {
            dayIndex = forced
        } else {
            let weekday = Calendar.current.component(.weekday, from: Date())
            switch weekday {
            case 2: dayIndex = 0
            case 3: dayIndex = 1
            case 4: dayIndex = 2
            case 5: dayIndex = 3
            case 6: dayIndex = 4
            default: dayIndex = -1
            }
        }
        
        guard dayIndex >= 0 else { return [] }
        
        // Read version to trigger SwiftUI re-render when selections change
        let _ = UserSession.shared.subjectSelectionsVersion
        let selections = UserSession.shared.user?.loadSubjectSelections() ?? [:]
        
        return timetable.slots.enumerated().compactMap { (slotIndex, slot) in
            let subjects = slot.subjects(for: dayIndex)
            guard !subjects.isEmpty else { return nil }
            
            let slotKey = "\(slotIndex)_\(dayIndex)"
            let selectedName = selections[slotKey]
            let selectedSubject = subjects.first(where: { $0.name == selectedName })
            
            let displayText: String
            let color: Color
            if let selected = selectedSubject {
                displayText = selected.name
                color = Color(hex: selected.color) ?? .blue
            } else {
                displayText = subjects.map(\.name).joined(separator: "/")
                color = subjects.first.flatMap { Color(hex: $0.color) } ?? .blue
            }
            
            let timeRange = formatTimeRange(start: slot.timeStart, end: slot.timeEnd)
            return (slot: slot, displayText: displayText, timeRange: timeRange, color: color)
        }
    }
    
    private func formatTimeRange(start: String, end: String) -> String {
        // Format "HH:mm:ss" to "HH:mm-HH:mm"
        let startShort = String(start.prefix(5))
        let endShort = String(end.prefix(5))
        return "\(startShort)-\(endShort)"
    }
    
    private func hasSubstitutionForPeriod(_ period: Int) -> Bool {
        guard let substitutions = substitutions else { return false }
        return substitutions.contains { $0.period == "\(period)" }
    }
    
    private func isCurrentLesson(slot: TimetableSlot) -> Bool {
        guard let start = slot.startComponents,
              let end = slot.endComponents else { return false }
        
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentTime)
        let minute = calendar.component(.minute, from: currentTime)
        
        let currentMinutes = hour * 60 + minute
        let startMinutes = start.hour * 60 + start.minute
        let endMinutes = end.hour * 60 + end.minute
        
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
