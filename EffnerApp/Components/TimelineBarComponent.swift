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
    let substitutionPlans: [SubstitutionPlan]?
    let currentTime: Date
    private let cardWidth: CGFloat = 100
    private let cardSpacing: CGFloat = 3
    
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
            title: "Timeline am \(DateFormatterUtil.formatToWeekdayDate(nextAvailableDay.date))",
            iconColor: .blue,
            removePadding: true
        ) {
            if timetable != nil {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: cardSpacing) {
                        ForEach(Array(todaySlots.enumerated()), id: \.offset) { index, slotInfo in
                            TimelineSubjectCard(
                                subject: slotInfo.displayText,
                                period: index + 1,
                                color: slotInfo.color,
                                hasSubstitution: hasSubstitutionForPeriod(index + 1),
                                timeRange: slotInfo.timeRange
                            )
                        }
                    }
                    .overlay(alignment: .topLeading) {
                        GeometryReader { geometry in
                            if let indicatorX = timelineIndicatorX {
                                Rectangle()
                                    .fill(.red)
                                    .frame(width: 1, height: geometry.size.height)
                                    .position(x: indicatorX, y: geometry.size.height / 2)
                            }
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
    
    /// Returns the substitutions for the day currently displayed in the timeline.
    /// This ensures that the timeline shows substitutions for the same day as the timetable,
    /// even if the current calendar day is a weekend or holiday.
    private var substitutionsForDisplayedDay: [Substitution]? {
        guard let plans = substitutionPlans else { return nil }
        
        let calendar = Calendar.current
        let displayedDate = calendar.startOfDay(for: nextAvailableDay.date)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for plan in plans {
            if let planDate = dateFormatter.date(from: plan.planDate),
               calendar.isDate(planDate, inSameDayAs: displayedDate) {
                return plan.substitutions
            }
        }
        return nil
    }
    
    private func hasSubstitutionForPeriod(_ period: Int) -> Bool {
        guard let substitutions = substitutionsForDisplayedDay else { return false }
        return substitutions.contains { $0.period == "\(period)" }
    }
    
    private var timelineIndicatorX: CGFloat? {
        guard !todaySlots.isEmpty else { return nil }

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentTime)
        let minute = calendar.component(.minute, from: currentTime)
        let second = calendar.component(.second, from: currentTime)

        let currentMinutes = Double(hour * 60 + minute) + (Double(second) / 60.0)

        let minuteRanges: [(start: Double, end: Double)] = todaySlots.compactMap { slotInfo in
            guard let start = slotInfo.slot.startComponents,
                  let end = slotInfo.slot.endComponents else { return nil }
            return (start: Double(start.hour * 60 + start.minute), end: Double(end.hour * 60 + end.minute))
        }

        guard minuteRanges.count == todaySlots.count else { return nil }

        // In einer Stunde: Position innerhalb der Karte berechnen.
        for (index, range) in minuteRanges.enumerated() {
            let duration = range.end - range.start
            guard duration > 0 else { continue }

            if currentMinutes >= range.start && currentMinutes <= range.end {
                let progress = (currentMinutes - range.start) / duration
                let x = CGFloat(index) * (cardWidth + cardSpacing) + CGFloat(progress) * cardWidth
                return min(max(x, 0), totalTimelineWidth)
            }
        }

        // Zwischen zwei Stunden: Position im Abstand zwischen den Karten.
        for index in 0..<(minuteRanges.count - 1) {
            let currentEnd = minuteRanges[index].end
            let nextStart = minuteRanges[index + 1].start
            let gap = nextStart - currentEnd

            guard gap > 0 else { continue }
            if currentMinutes > currentEnd && currentMinutes < nextStart {
                let gapProgress = (currentMinutes - currentEnd) / gap
                let x = CGFloat(index) * (cardWidth + cardSpacing) + cardWidth + CGFloat(gapProgress) * cardSpacing
                return min(max(x, 0), totalTimelineWidth)
            }
        }

        // Außerhalb der sichtbaren Timeline (vor erster/nach letzter Stunde): kein Zeiger.
        return nil
    }

    private var totalTimelineWidth: CGFloat {
        let count = CGFloat(todaySlots.count)
        guard count > 0 else { return 0 }
        return count * cardWidth + (count - 1) * cardSpacing
    }

}

// MARK: - Timeline Subject Card
struct TimelineSubjectCard: View {
    let subject: String
    let period: Int
    let color: Color
    let hasSubstitution: Bool
    let timeRange: String
    
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
    }
}
