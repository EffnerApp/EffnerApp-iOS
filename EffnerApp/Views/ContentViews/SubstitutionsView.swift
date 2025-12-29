//
//  SubstitutionsView.swift
//  EffnerApp
//
//  Created by Luis Bros on 08.11.25.
//

import SwiftUI
import Combine

enum PlanTimeType {
    case PAST, TODAY, FUTURE
}

struct SubstitutionsView: View {
    @EnvironmentObject private var substitutionsCache: SubstitutionsCache
    
    init(isPreview: Bool = false) {
        if isPreview {
            SubstitutionsCache.shared.saveSubstitutions(MockSubstitution.mockSubstitutionPlans)
        }
    }
    
    var body: some View {
        BaseContentView(
            caches: [substitutionsCache],
            navigationTitle: "Vertretungen",
            errorTitle: "Vertretungsplan nicht verfügbar",
            errorDescription: "Der Vertretungsplan konnte nicht geladen werden oder steht derzeit nicht zur Verfügung (z.B. Ferien). Bitte versuche es später erneut.",
            useScrollViewReader: true,
            scrollToId: { cache in
                if let plans = substitutionsCache.cachedSubstitutionPlans?.plans,
                   let firstFuturePlan = plans.first(where: { getPlanTimeType($0.date) == PlanTimeType.FUTURE }) {
                    return "futureSubstitution_\(firstFuturePlan.date)"
                }
                return nil
            },
            content: { cache in
                List {
                    if let plans = substitutionsCache.cachedSubstitutionPlans?.plans {
                        // Vergangene Tage
                        ForEach(plans.filter { getPlanTimeType($0.date) == .PAST }, id: \.date) { plan in
                            Section(header: SubstitutionSeparatorView(date: plan.date, planTimeType: .PAST)) {
                                SubstitutionDayContent(plan: plan)
                                    .listRowBackground(Color(UIColor.secondarySystemBackground))
                            }
                            .id("pastSubstitution_\(plan.date)")
                        }
                        
                        ForEach(plans.filter { getPlanTimeType($0.date) == .TODAY }, id: \.date) { plan in
                            Section(header: SubstitutionSeparatorView(date: plan.date, planTimeType: .TODAY)) {
                                SubstitutionDayContent(plan: plan)
                                    .listRowBackground(Color(UIColor.secondarySystemBackground))
                            }
                            .id("todaysSubstitution_\(plan.date)")
                        }
                        
                        // Zukünftige Tage
                        ForEach(plans.filter { getPlanTimeType($0.date) == .FUTURE }, id: \.date) { plan in
                            Section(header: SubstitutionSeparatorView(date: plan.date, planTimeType: .FUTURE)) {
                                SubstitutionDayContent(plan: plan)
                                    .listRowBackground(Color(UIColor.secondarySystemBackground))
                            }
                            .id("futureSubstitution_\(plan.date)")
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color(UIColor.systemBackground))
            },
            skeletonView: {
                SubstitutionSkeletonView()
            }
        )
    }
    
    private func getPlanTimeType(_ dateString: String) -> PlanTimeType {
        let germanFormatter = DateFormatter()
        germanFormatter.dateFormat = "dd.MM.yyyy"
        
        if let date = germanFormatter.date(from: dateString) {
            let calendar = Calendar.current
            let today = Date()
            
            if calendar.isDate(date, inSameDayAs: today) {
                return .TODAY
            } else if date < today {
                return .PAST
            } else {
                return .FUTURE
            }
        }
        return .FUTURE
    }
}

struct SubstitutionDayContent: View {
    let plan: SubstitutionPlan
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Prüfen ob es irgendwelche Ereignisse gibt
            let hasInfos = plan.infos?.contains(where: { !$0.isEmpty }) ?? false
            let hasAbsent = !plan.absent.isEmpty
            let hasSubstitutions = !(plan.substitutions?.isEmpty ?? true)
            let hasAnyEvents = hasInfos || hasAbsent || hasSubstitutions
            
            if !hasAnyEvents {
                // Keine Ereignisse
                Label("Keinerlei Ereignisse", systemImage: "text.page.slash")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
            } else {
                // Informationen
                if hasInfos, let infos = plan.infos {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Informationen")
                            .font(.headline)
                        
                        ForEach(infos.filter { !$0.isEmpty }, id: \.self) { info in
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
                if hasAbsent {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Abwesende Klassen")
                            .font(.headline)
                        
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
                if hasSubstitutions, let substitutions = plan.substitutions {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Vertretungen")
                            .font(.headline)
                        
                        ForEach(Array(substitutions.enumerated()), id: \.element.id) { index, substitution in
                            SubstitutionRowView(
                                substitution: substitution,
                                isLast: index == substitutions.count - 1
                            )
                        }
                    }
                    .padding(.horizontal, 12)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

struct SubstitutionRowView: View {
    let substitution: Substitution
    let isLast: Bool
    
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
                            HStack(spacing: 4) {
                                Image(systemName: "door.left.hand.open")
                                    .font(.subheadline)
                                    .foregroundColor(.orange)
                                Text(room)
                                    .font(.subheadline)
                            }
                        }
                        
                        if let info = substitution.info {
                            Text(info)
                                .font(.subheadline)
                        }
                    }
                }
            }
            .padding(.vertical, 4)
            
            if !isLast {
                Divider()
            }
        }
    }
}

struct SubstitutionSeparatorView: View {
    let date: String
    var planTimeType: PlanTimeType
    
    var body: some View {
        HStack {
            if planTimeType == .PAST {
                Text("Vergangene Tage")
                    .font(.headline)
            } else if planTimeType == .TODAY {
                Text("Heute")
                    .font(.headline)
            } else if planTimeType == .FUTURE {
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
    }
}

#Preview {
    SubstitutionsView(isPreview: true)
        .environmentObject(SubstitutionsCache.shared)
        .environmentObject(UserSession.shared)
        .environmentObject(ClassesCache.shared)
}
