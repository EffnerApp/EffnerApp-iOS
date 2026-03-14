//
//  HomeView.swift
//  EffnerApp
//
//  Created by Luis Bros on 21.07.25.
//

import SwiftUI

struct HomeView: View {
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
    @State private var showCampusCafeView = false
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        BaseContentView(
            caches: [holidaysCache],
            navigationTitle: "Jetzt",
            errorTitle: "error",
            errorDescription: "could not load home view") { cache in
                ScrollView {
                    VStack(spacing: 16) {
                        // Bento-Grid Layout
                        BentoGridLayout(
                            currentTime: currentTime,
                            importantInfos: importantInfos,
                            todaySubstitutions: todaySubstitutions,
                            showHolidaysView: $showHolidaysView,
                            showCampusCafeView: $showCampusCafeView
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
            .sheet(isPresented: $showCampusCafeView) {
                CampusCafeView()
            }
    }
    
    // MARK: - Computed Properties
    private var todaySubstitutions: [Substitution]? {
        guard let plans = substitutionsCache.cachedResponse?.plans else { return nil }
        
        let today = Calendar.current.startOfDay(for: Date())
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        for plan in plans {
            if let planDate = dateFormatter.date(from: plan.planDate),
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
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Infos aus den nächsten 2 Tagen sammeln
        for plan in plans {
            if let planDate = dateFormatter.date(from: plan.planDate),
               planDate >= today  {
                infos.append(contentsOf: plan.infos)
            }
        }
        
        return infos
    }
}

// MARK: - Bento Grid Layout
struct BentoGridLayout: View {
    let currentTime: Date
    let importantInfos: [String]
    let todaySubstitutions: [Substitution]?
    @Binding var showHolidaysView: Bool
    @Binding var showCampusCafeView: Bool
        
    var body: some View {
        VStack(spacing: 12) {
            TimelineBarComponent(
                substitutions: todaySubstitutions,
                currentTime: currentTime,
            )
            
            // Wichtige Infos (nimmt volle Breite, wenn vorhanden)
            if !importantInfos.isEmpty {
                ImportantInfoWidget(infos: importantInfos)
            }
            
            // 2-Spalten-Grid für weitere Widgets
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                
                /*
                GridWidget(
                    icon: "plus.forwardslash.minus",
                    title: "Noten",
                    iconColor: Color.green,
                    contextActions: []
                ) {
                    Text("⌀1,3")
                        .font(.system(size: 54))
                }
                 */
                
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
                    contextActions: [
                        GridWidgetAction(title: "Öffnen", icon: "eyes.inverse", action: {
                            showCampusCafeView = true
                        })
                    ]
                ) {
                } preview: {
                    CampusCafeView()
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
