//
//  ContentView.swift
//  EffnerApp
//
//  Created by Luis Bros on 29.06.25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var substitutionsCache: SubstitutionsCache
    
    init(isPreview: Bool = false) {
        if isPreview {
            SubstitutionsCache.shared.saveSubstitutions(MockSubstitution.mockSubstitutionPlans)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            TabView {
                HomeView()
                    .tabItem {
                        Image(systemName: "waveform.path.ecg.text.rtl")
                        Text("Jetzt")
                    }
                SubstitutionsView()
                    .tabItem {
                        Image(systemName: "arrow.trianglehead.branch")
                        Text("Vertretungen")
                    }
                    .badge(todaySubstitutionCount)
                ExamsView()
                    .tabItem {
                        Image(systemName: "graduationcap")
                        Text("Klausuren")
                    }
                TimetableView()
                    .tabItem {
                        Image(systemName: "calendar.day.timeline.right")
                        Text("Stundenplan")
                    }
            }
        }
    }
    
    // Berechnet die Anzahl der Vertretungen für heute oder den nächsten verfügbaren Tag
    private var todaySubstitutionCount: Int {
        guard let plans = substitutionsCache.cachedSubstitutionPlans?.plans else {
            return 0
        }
        
        let germanFormatter = DateFormatter()
        germanFormatter.dateFormat = "dd.MM.yyyy"
        let today = Date()
        
        // Suche zuerst nach dem heutigen Plan
        if let todayPlan = plans.first(where: { plan in
            guard let planDate = germanFormatter.date(from: plan.date) else { return false }
            return Calendar.current.isDate(planDate, inSameDayAs: today)
        }) {
            return todayPlan.substitutions?.count ?? 0
        }
        
        // Wenn kein Plan für heute existiert, nehme den nächsten zukünftigen Plan
        let futurePlans = plans
            .compactMap { plan -> (date: Date, plan: SubstitutionPlan)? in
                guard let planDate = germanFormatter.date(from: plan.date),
                      planDate >= today else { return nil }
                return (date: planDate, plan: plan)
            }
            .sorted { $0.date < $1.date }
        
        if let nextPlan = futurePlans.first {
            return nextPlan.plan.substitutions?.count ?? 0
        }
        
        return 0
    }
}

#Preview {
    ContentView(isPreview: true)
        .environmentObject(SubstitutionsCache.shared)
        .environmentObject(UserSession.shared)
        .environmentObject(ClassesCache.shared)
}
