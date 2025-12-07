//
//  HomeView.swift
//  EffnerApp
//
//  Created by Luis Bros on 21.07.25.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var timetableCache = TimetablesCache.shared
    @ObservedObject var substitutionsCache = SubstitutionsCache.shared
    @ObservedObject var holidaysCache = HolidaysCache.shared
    
    init(isPreview: Bool = false) {
        if isPreview {
            TimetablesCache.shared.saveTimetables(MockTimetable.mockTimetable)
            SubstitutionsCache.shared.saveSubstitutions(MockSubstitution.mockSubstitutionPlans)
            HolidaysCache.shared.saveHolidays(MockHolidays.mockHolidays)
        }
    }

    
    @State private var currentTime = Date()
    @State private var showHolidaysView = false
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        BaseContentView(
            caches: [timetableCache, substitutionsCache, holidaysCache],
            navigationTitle: "Jetzt",
            errorTitle: "error",
            errorDescription: "errorrr") { cache in
                ScrollView {
                    VStack(spacing: 16) {
                        // Bento-Grid Layout
                        BentoGridLayout(
                            timetable: timetableCache.cachedResponse?.data.first,
                            schedule: timetableCache.cachedResponse?.schedule,
                            currentTime: currentTime,
                            importantInfos: importantInfos,
                            todaySubstitutions: todaySubstitutions,
                            showHolidaysView: $showHolidaysView
                        )
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                .scrollBounceBehavior(.basedOnSize)
            } skeletonView: {
                HomeSkeletonView()
            }
            .sheet(isPresented: $showHolidaysView) {
                HolidaysView()
                    .environmentObject(holidaysCache)
            }
    }
    
    // MARK: - Computed Properties
    private var todaySubstitutions: [Substitution]? {
        guard let plans = substitutionsCache.cachedResponse?.plans else { return nil }
        
        let today = Calendar.current.startOfDay(for: Date())
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        
        for plan in plans {
            if let planDate = dateFormatter.date(from: plan.date),
               Calendar.current.isDate(planDate, inSameDayAs: today) {
                return plan.substitutions
            }
        }
        return nil
    }
    
    private var importantInfos: [String] {
        guard let plans = substitutionsCache.cachedResponse?.plans else { return [] }
        
        var infos: [String] = []
        
        let today = Calendar.current.startOfDay(for: Date())
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        
        // Infos aus den nächsten 2 Tagen sammeln
        for plan in plans {
            if let planDate = dateFormatter.date(from: plan.date),
               planDate >= today  {
                if let planInfos = plan.infos {
                    infos.append(contentsOf: planInfos)
                }
            }
        }
        
        return infos
    }
}

// MARK: - Bento Grid Layout
struct BentoGridLayout: View {
    let timetable: Timetable?
    let schedule: [Array<Int>?]?
    let currentTime: Date
    let importantInfos: [String]
    let todaySubstitutions: [Substitution]?
    @Binding var showHolidaysView: Bool
    
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
            if dayIndex >= 0 && dayIndex < timetable.lessons.count {
                let lessons = timetable.lessons[dayIndex].filter { !$0.isEmpty }
                if !lessons.isEmpty {
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
    
    var body: some View {
        VStack(spacing: 12) {
            // Timeline Widget (nimmt volle Breite)
            GridWidget(
                icon: "clock.fill",
                title: "Timeline am \(DateFormatterUtil.formatToShortDate(nextAvailableDay.date))",
                iconColor: .blue,
                removePadding: true
            ) {
                TimelineBarComponent(
                    timetable: timetable,
                    schedule: schedule,
                    substitutions: todaySubstitutions,
                    currentTime: currentTime,
                    forcedDayIndex: nextAvailableDay.dayIndex
                )
            }
            
            // Wichtige Infos (nimmt volle Breite, wenn vorhanden)
            if !importantInfos.isEmpty {
                ImportantInfoWidget(infos: importantInfos)
            }
            
            // 2-Spalten-Grid für weitere Widgets
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                
                // Platzhalter für weitere Widgets
                GridWidget(
                    icon: "plus.forwardslash.minus",
                    title: "Noten",
                    iconColor: Color.green,
                    contextActions: []
                ) {
                    Text("⌀1,3")
                        .font(.system(size: 54))
                }
                
                GridWidget(
                    icon: "beach.umbrella.fill",
                    title: "Ferien",
                    iconColor: Color.yellow,
                    contextActions: [
                        GridWidgetAction(title: "Öffnen", icon: "eyes.inverse", action: {
                            showHolidaysView = true
                        })
                    ]
                ) {
                    VStack(spacing: 4) {
                        if let nextHoliday = getNextHoliday() {
                            Text(nextHoliday.name)
                                .font(.system(size: 28, weight: .semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                            Text(formatDateRange(start: nextHoliday.startsOn, end: nextHoliday.endsOn))
                                .font(.system(size: 14))
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Keine")
                                .font(.system(size: 32))
                        }
                    }
                } preview: {
                    HolidaysView()
                        .environmentObject(HolidaysCache.shared)
                        .environment(UserSession.shared)
                }
                
                GridWidget(
                    icon: "fork.knife",
                    title: "Speiseplan",
                    iconColor: Color.purple,
                ) {
                    Text("Lecker")
                        .font(.system(size: 42))
                }
                
                
            }
        }
    }
    
    // MARK: - Helper Functions
    private func getNextHoliday() -> Holiday? {
        guard let holidays = HolidaysCache.shared.cachedResponse?.data else { return nil }
        
        let now = Date()
        let isoFormatter = ISO8601DateFormatter()
        let germanFormatter = DateFormatter()
        germanFormatter.dateFormat = "yyyy-MM-dd"
        
        // Filtere und sortiere zukünftige Ferien
        let futureHolidays = holidays.filter { holiday in
            if let startDate = isoFormatter.date(from: holiday.startsOn) ?? germanFormatter.date(from: holiday.startsOn) {
                return startDate >= now
            }
            return false
        }.sorted { holiday1, holiday2 in
            let date1 = isoFormatter.date(from: holiday1.startsOn) ?? germanFormatter.date(from: holiday1.startsOn) ?? Date.distantFuture
            let date2 = isoFormatter.date(from: holiday2.startsOn) ?? germanFormatter.date(from: holiday2.startsOn) ?? Date.distantFuture
            return date1 < date2
        }
        
        return futureHolidays.first
    }
    
    private func formatDateRange(start: String, end: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        let germanFormatter = DateFormatter()
        germanFormatter.dateFormat = "yyyy-MM-dd"
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "d. MMM"
        displayFormatter.locale = Locale(identifier: "de_DE")
        
        guard let startDate = isoFormatter.date(from: start) ?? germanFormatter.date(from: start),
              let endDate = isoFormatter.date(from: end) ?? germanFormatter.date(from: end) else {
            return ""
        }
        
        return "\(displayFormatter.string(from: startDate)) - \(displayFormatter.string(from: endDate))"
    }
    
    private func formatDate(_ dateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        let germanFormatter = DateFormatter()
        germanFormatter.dateFormat = "yyyy-MM-dd"
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "d. MMMM yyyy"
        displayFormatter.locale = Locale(identifier: "de_DE")
        
        guard let date = isoFormatter.date(from: dateString) ?? germanFormatter.date(from: dateString) else {
            return dateString
        }
        
        return displayFormatter.string(from: date)
    }
}



// MARK: - Important Info Widget
struct ImportantInfoWidget: View {
    let infos: [String]
    
    var body: some View {
        GridWidget(
            icon: "exclamationmark.triangle.fill",
            title: "Wichtig",
            iconColor: .orange
        ) {
            ForEach(Array(infos.prefix(3).enumerated()), id: \.offset) { _, info in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(.orange)
                        .frame(width: 6, height: 6)
                        .padding(.top, 6)
                    
                    Text(info)
                        .font(.subheadline)
                        .lineLimit(3)
                }
            }
        }
    }
}

// MARK: - Quick Action Widget
struct QuickActionWidget: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        GridWidget(
            icon: icon,
            title: title,
            iconColor: color
        ) {
            Spacer()
        }
    }
}

#Preview {
    HomeView(isPreview: true)
        .environmentObject(SubstitutionsCache.shared)
        .environmentObject(UserSession.shared)
        .environmentObject(ClassesCache.shared)
        .environmentObject(ExamsCache.shared)
        .environmentObject(TimetablesCache.shared)
        .environmentObject(HolidaysCache.shared)
}
