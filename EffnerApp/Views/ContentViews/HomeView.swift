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
    @ObservedObject var examsCache = ExamsCache.shared
    
    init(isPreview: Bool = false) {
        if isPreview {
            ExamsCache.shared.saveExams(MockExam.mockExams)
            TimetablesCache.shared.saveTimetables(MockTimetable.mockTimetable)
            SubstitutionsCache.shared.saveSubstitutions(MockSubstitution.mockSubstitutionPlans)
        }
    }

    
    @State private var currentTime = Date()
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationStack {
            Group {
                if hasError {
                    ContentUnavailableView {
                        Label {
                            Text("Keine Verbindung")
                        } icon: {
                            Image(systemName: "wifi.slash")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.yellow, .orange)
                        }
                    } description: {
                        Text("Die Daten konnten nicht geladen werden. Bitte überprüfe deine Internetverbindung.")
                    } actions: {
                        Button("Erneut versuchen") {
                            Task {
                                await refreshAllData()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else if isLoading {
                    HomeSkeletonView()
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Timeline-Leiste (horizontaler Tagesüberblick)
                            TimelineBarView(
                                timetable: timetableCache.cachedResponse?.data.first,
                                schedule: timetableCache.cachedResponse?.schedule,
                                substitutions: todaySubstitutions,
                                currentTime: currentTime
                            )
                            .padding(.horizontal)
                            
                            // Bento-Grid Layout
                            BentoGridLayout(
                                upcomingExams: upcomingExams,
                                importantInfos: importantInfos,
                                todaySubstitutions: todaySubstitutions
                            )
                            .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                }
            }
            .navigationTitle("Jetzt")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                ToolbarComponent()
            }
            .onReceive(timer) { _ in
                currentTime = Date()
            }
        }
    }
    
    // MARK: - Loading & Error States
    
    private var hasError: Bool {
        timetableCache.hasError || substitutionsCache.hasError || examsCache.hasError
    }
    
    private var isLoading: Bool {
        timetableCache.isEmpty && substitutionsCache.isEmpty && examsCache.isEmpty
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
    
    private var upcomingExams: [Exam] {
        guard let exams = examsCache.cachedResponse?.exams else { return [] }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        let now = Date()
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now
        
        return exams.filter { exam in
            guard let examDate = dateFormatter.date(from: exam.date) else { return false }
            return examDate >= now && examDate <= nextWeek
        }
        .sorted { exam1, exam2 in
            guard let date1 = dateFormatter.date(from: exam1.date),
                  let date2 = dateFormatter.date(from: exam2.date) else {
                return false
            }
            return date1 < date2
        }
    }
    
    private var importantInfos: [String] {
        guard let plans = substitutionsCache.cachedResponse?.plans else { return [] }
        
        var infos: [String] = []
        
        // Infos aus den nächsten 2 Tagen sammeln
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd.MM.yyyy"
        
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today) ?? today
        
        for plan in plans {
            if let planDate = dateFormatter.date(from: plan.date),
               planDate >= today && planDate <= tomorrow {
                if let planInfos = plan.infos {
                    infos.append(contentsOf: planInfos)
                }
            }
        }
        
        return infos
    }
    
    private func refreshAllData() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await timetableCache.refreshCache() }
            group.addTask { await substitutionsCache.refreshCache() }
            group.addTask { await examsCache.refreshCache() }
        }
    }
}

// MARK: - Timeline Bar View
struct TimelineBarView: View {
    let timetable: Timetable?
    let schedule: [Array<Int>?]?
    let substitutions: [Substitution]?
    let currentTime: Date
    
    @State private var selectedDay: Int = Calendar.current.component(.weekday, from: Date())
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            
            if let timetable = timetable {
                VStack {
                    Text("Timeline")
                        .font(.headline)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 2) {
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
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                    }

                }
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.background.secondary)
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                )
            } else {
                TimelineSkeletonView()
            }
        }
        .onAppear {
            // Setze den aktuellen Wochentag (Montag = 1, ..., Freitag = 5)
            let weekday = Calendar.current.component(.weekday, from: Date())
            // Konvertiere zu Montag = 0, Dienstag = 1, etc.
            selectedDay = weekday == 1 ? 4 : weekday - 2
        }
    }
    
    private var todayLessons: [String] {
        guard let timetable = timetable else { return [] }
        
        let weekday = Calendar.current.component(.weekday, from: Date())
        let dayIndex = weekday == 1 ? 4 : weekday - 2 // Montag = 0, Sonntag wird zu Freitag
        
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



// MARK: - Bento Grid Layout
struct BentoGridLayout: View {
    let upcomingExams: [Exam]
    let importantInfos: [String]
    let todaySubstitutions: [Substitution]?
    
    var body: some View {
        VStack(spacing: 12) {
            // Wichtige Infos (nimmt volle Breite, wenn vorhanden)
            if !importantInfos.isEmpty {
                ImportantInfoWidget(infos: importantInfos)
            }
            
            // 2-Spalten-Grid für weitere Widgets
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                
                // Nächste Klausur
                if let nextExam = upcomingExams.first {
                    NextExamWidget(exam: nextExam)
                        .gridCellColumns(2)
                }
                
                // Vertretungen Widget
                if let substitutions = todaySubstitutions, !substitutions.isEmpty {
                    SubstitutionsWidget(count: substitutions.count)
                }
                
                // Platzhalter für weitere Widgets
                QuickActionWidget(
                    icon: "book.fill",
                    title: "Aufgaben",
                    color: .blue
                )
                
                QuickActionWidget(
                    icon: "calendar",
                    title: "Termine",
                    color: .green
                )
                
                QuickActionWidget(
                    icon: "bell.fill",
                    title: "Mitteilungen",
                    color: .orange
                )
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

// MARK: - Next Exam Widget
struct NextExamWidget: View {
    let exam: Exam
    
    private var examDate: Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return formatter.date(from: exam.date)
    }
    
    private var daysUntilExam: Int? {
        guard let date = examDate else { return nil }
        return Calendar.current.dateComponents([.day], from: Date(), to: date).day
    }
    
    var body: some View {
        GridWidget(
            icon: "doc.text.fill",
            title: "Nächste Klausur",
            iconColor: .red
        ) {
            VStack(alignment: .leading, spacing: 4) {
                Text(exam.name)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                if let course = exam.course {
                    Text(course)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                if let days = daysUntilExam {
                    Text(days == 0 ? "Heute!" : days == 1 ? "Morgen!" : "In \(days) Tagen")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.red)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(.red.opacity(0.15))
                        )
                        .padding(.top, 4)
                }
            }
        }
    }
}

// MARK: - Substitutions Widget
struct SubstitutionsWidget: View {
    let count: Int
    
    var body: some View {
        GridWidget(
            icon: "arrow.triangle.2.circlepath",
            title: "Vertretungen",
            iconColor: .orange
        ) {
            Text("\(count)")
                .font(.largeTitle)
                .fontWeight(.bold)
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
