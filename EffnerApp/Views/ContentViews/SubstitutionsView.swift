//
//  SubstitutionsView.swift
//  EffnerApp
//
//  Created by Luis Bros on 08.11.25.
//

import SwiftUI

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
            errorSystemImage: "waveform.path.ecg",
            errorDescription: "Der Vertretungsplan konnte nicht geladen werden oder steht derzeit nicht zur Verfügung (z.B. Ferien). Bitte versuche es später erneut.",
            useScrollViewReader: true,
            scrollToId: { cache in
                if let plans = substitutionsCache.cachedSubstitutionPlans?.plans,
                   let firstFuturePlan = plans.first(where: { getPlanTimeType($0.planDate) == PlanTimeType.FUTURE }) {
                    return "futureSubstitution_\(firstFuturePlan.planDate)"
                }
                return nil
            },
            content: { cache in
                List {
                    if let plans = substitutionsCache.cachedSubstitutionPlans?.plans {
                        // Vergangene Tage
                        ForEach(plans.filter { getPlanTimeType($0.planDate) == .PAST }) { plan in
                            Section(header: SubstitutionSeparatorView(date: plan.planDate, planTimeType: .PAST)) {
                                SubstitutionDayContent(plan: plan)
                                    .listRowBackground(Color(UIColor.secondarySystemBackground))
                            }
                            .id("pastSubstitution_\(plan.planDate)")
                        }
                        
                        // Heute
                        ForEach(plans.filter { getPlanTimeType($0.planDate) == .TODAY }) { plan in
                            Section(header: SubstitutionSeparatorView(date: plan.planDate, planTimeType: .TODAY)) {
                                SubstitutionDayContent(plan: plan)
                                    .listRowBackground(Color(UIColor.secondarySystemBackground))
                            }
                            .id("todaysSubstitution_\(plan.planDate)")
                        }
                        
                        // Zukünftige Tage
                        ForEach(plans.filter { getPlanTimeType($0.planDate) == .FUTURE }) { plan in
                            Section(header: SubstitutionSeparatorView(date: plan.planDate, planTimeType: .FUTURE)) {
                                SubstitutionDayContent(plan: plan)
                                    .listRowBackground(Color(UIColor.secondarySystemBackground))
                            }
                            .id("futureSubstitution_\(plan.planDate)")
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
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        if let date = formatter.date(from: dateString) {
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
            let hasInfos = !plan.infos.isEmpty
            let hasAbsences = !plan.absences.isEmpty
            let hasSubstitutions = !plan.substitutions.isEmpty
            let hasAnyEvents = hasInfos || hasAbsences || hasSubstitutions
            
            if !hasAnyEvents {
                // Keine Ereignisse
                Label("Keinerlei Ereignisse", systemImage: "text.page.slash")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
            } else {
                // Informationen
                if hasInfos {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Informationen")
                            .font(.headline)
                        
                        ForEach(plan.infos.filter { !$0.isEmpty }, id: \.self) { info in
                            HStack(alignment: .top) {
                                Image(systemName: "info.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 14))
                                Text(info)
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding(.bottom, 8)
                }
                
                // Abwesende Klassen
                if hasAbsences {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Abwesende Klassen")
                            .font(.headline)
                        
                        ForEach(plan.absences) { absence in
                            HStack {
                                Text(absence.className)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("•")
                                    .foregroundColor(.secondary)
                                Text("Stunden: \(absence.periods)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.bottom, 8)
                }
                
                // Vertretungen
                if hasSubstitutions {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Vertretungen")
                            .font(.headline)
                        
                        ForEach(Array(plan.substitutions.enumerated()), id: \.element.id) { index, substitution in
                            SubstitutionRowView(
                                substitution: substitution,
                                isLast: index == plan.substitutions.count - 1
                            )
                        }
                    }
                }
            }
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 12)
    }
}

struct SubstitutionRowView: View {
    @EnvironmentObject public var session: UserSession
    let substitution: Substitution
    let isLast: Bool
    
    var body: some View {
        VStack() {
            HStack(alignment: .center) {
                // Stunde
                Text("\(substitution.period).")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.trailing, 4)
                
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
                
                if(substitution.klassName != session.user?.klasses.first) {
                    Spacer()
                    Text("\(substitution.klassName)")
                        .font(.callout)
                        .padding(.leading, 2)
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
    
    private var formattedDate: String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "dd.MM.yyyy"
        
        if let parsed = inputFormatter.date(from: date) {
            return outputFormatter.string(from: parsed)
        }
        return date
    }
    
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
            
            Text(formattedDate)
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
