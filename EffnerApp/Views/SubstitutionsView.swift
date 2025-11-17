//
//  SubstitutionsView.swift
//  EffnerApp
//
//  Created by Luis Bros on 08.11.25.
//

import SwiftUI
import Combine

struct SubstitutionsView: View {
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil
    @EnvironmentObject private var substitutionsCache: SubstitutionsCache
    
    init(isPreview: Bool = false) {
        if isPreview {
            SubstitutionsCache.shared.saveSubstitutions(MockSubstitution.mockSubstitutionPlans)
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                List {
                    if substitutionsCache.hasError {
                        ContentUnavailableView(
                            "Vertretungsplan nicht verfügbar",
                            systemImage: "calendar.badge.exclamationmark",
                            description: Text("Der Vertretungsplan konnte nicht geladen werden. Bitte versuche es später erneut.")
                        )
                    } else if substitutionsCache.cachedSubstitutionPlans == nil {
                        SubstitutionSkeletonView()
                    } else if let plans = substitutionsCache.cachedSubstitutionPlans?.plans {
                        // Vergangene Tage
                        ForEach(plans.filter { isPastDate($0.date) }, id: \.date) { plan in
                            Section(header: SubstitutionSeparatorView(date: plan.date, isPast: true)) {
                                SubstitutionDayContent(plan: plan)
                            }
                            .id("pastSubstitution_\(plan.date)")
                        }
                        
                        // Zukünftige Tage
                        ForEach(plans.filter { !isPastDate($0.date) }, id: \.date) { plan in
                            Section(header: SubstitutionSeparatorView(date: plan.date, isPast: false)) {
                                SubstitutionDayContent(plan: plan)
                            }
                            .id("futureSubstitution_\(plan.date)")
                        }
                    }
                }
                .onAppear {
                    if let plans = substitutionsCache.cachedSubstitutionPlans?.plans,
                       let firstFuturePlan = plans.first(where: { !isPastDate($0.date) }) {
                        proxy.scrollTo("futureSubstitution_\(firstFuturePlan.date)", anchor: .top)
                    }
                }
                .navigationTitle("Vertretungsplan")
                .toolbarTitleDisplayMode(.inlineLarge)
                .toolbar {
                    ToolbarComponent()
                }
            }
        }
    }
    
    private func isPastDate(_ dateString: String) -> Bool {
        let germanFormatter = DateFormatter()
        germanFormatter.dateFormat = "dd.MM.yyyy"
        
        if let date = germanFormatter.date(from: dateString) {
            return date < Date()
        }
        return false
    }
}

struct SubstitutionDayContent: View {
    let plan: SubstitutionPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Informationen
            if let infos = plan.infos, !infos.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Informationen")
                        .font(.headline)
                        .padding(.top, 8)
                    
                    ForEach(infos.compactMap { $0 }, id: \.self) { info in
                        HStack(alignment: .top) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 14))
                            Text(info)
                                .font(.subheadline)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
            
            // Abwesende Klassen
            if !plan.absent.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Abwesende Klassen")
                        .font(.headline)
                        .padding(.top, 8)
                    
                    ForEach(plan.absent) { absent in
                        HStack {
                            Text(absent.className)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("•")
                                .foregroundColor(.secondary)
                            Text("Stunden: \(absent.periods)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
            
            // Vertretungen
            if let substitutions = plan.substitutions, !substitutions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Vertretungen")
                        .font(.headline)
                        .padding(.top, 8)
                    
                    ForEach(substitutions.compactMap { $0 }) { substitution in
                        SubstitutionRowView(substitution: substitution)
                    }
                }
                .padding(.horizontal, 12)
            }
        }
        .padding(.vertical, 8)
    }
}

struct SubstitutionRowView: View {
    let substitution: Substitution
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center) {
                // Stunde
                Text("\(substitution.period).")
                    .font(.title2)
                    .fontWeight(.bold)
                    .frame(width: 40, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 2) {
                    // Lehrer und Vertretung
                    HStack(spacing: 4) {
                        if let teacher = substitution.teacher {
                            Text(teacher)
                                .font(.body)
                                .strikethrough()
                                .foregroundColor(.secondary)
                        }
                        
                        if substitution.teacher != nil && substitution.substitute != nil {
                            Image(systemName: "arrow.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let substitute = substitution.substitute {
                            Text(substitute)
                                .font(.body)
                                .fontWeight(.medium)
                        }
                    }
                    
                    // Raum und Info
                    HStack(spacing: 8) {
                        if let room = substitution.room {
                            Label(room, systemImage: "door.left.hand.open")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if let info = substitution.info {
                            Text(info)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
            
            Divider()
        }
    }
}

struct SubstitutionSeparatorView: View {
    let date: String
    var isPast: Bool = true
    
    var body: some View {
        HStack {
            if isPast {
                Text("Vergangene Tage")
                    .font(.headline)
            } else {
                Text("Zukünftige Tage")
                    .font(.headline)
            }
            
            Spacer()
            
            Text(date)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground))
    }
}

#Preview {
    SubstitutionsView(isPreview: true)
}
