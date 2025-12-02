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
    
    init(isPreview: Bool = false) {
        if isPreview {
            TimetablesCache.shared.saveTimetables(MockTimetable.mockTimetable)
            SubstitutionsCache.shared.saveSubstitutions(MockSubstitution.mockSubstitutionPlans)
        }
    }

    
    @State private var currentTime = Date()
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        BaseContentView(
            caches: [timetableCache, substitutionsCache],
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
                            todaySubstitutions: todaySubstitutions
                        )
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
                .scrollBounceBehavior(.basedOnSize)
            } skeletonView: {
                HomeSkeletonView()
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
    
    var body: some View {
        VStack(spacing: 12) {
            // Timeline Widget (nimmt volle Breite)
            GridWidget(
                icon: "clock.fill",
                title: "Timeline am \(DateFormatterUtil.formatToShortDate())",
                iconColor: .blue,
                removePadding: true
            ) {
                TimelineBarComponent(
                    timetable: timetable,
                    schedule: schedule,
                    substitutions: todaySubstitutions,
                    currentTime: currentTime
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
                        .font(.system(size: 54, weight: .bold))
                }
                
                GridWidget(
                    icon: "beach.umbrella.fill",
                    title: "Ferien",
                    iconColor: Color.yellow,
                ) {
                    Text("Ostern")
                        .font(.system(size: 42, weight: .bold))
                }
                
                GridWidget(
                    icon: "fork.knife",
                    title: "Speiseplan",
                    iconColor: Color.purple,
                ) {
                    Text("Lecker")
                        .font(.system(size: 42, weight: .bold))
                }
                
                
            }
        }
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
}
