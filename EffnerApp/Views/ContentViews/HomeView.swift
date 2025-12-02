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
    
    @State private var currentTime = Date()
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationStack {
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
            .navigationTitle("Jetzt")
            .toolbarTitleDisplayMode(.large)
            .toolbar {
                ToolbarComponent()
            }
            .onReceive(timer) { _ in
                currentTime = Date()
            }
            .refreshable {
                await refreshAllData()
            }
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
            Text("Heute")
                .font(.headline)
                .foregroundStyle(.secondary)
            
            if let timetable = timetable {
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
        // Standardzeiten für deutsche Schulen
        let times = [
            "08:00-08:45",
            "08:50-09:35",
            "09:40-10:25",
            "10:45-11:30",
            "11:35-12:20",
            "12:25-13:10",
            "13:15-14:00",
            "14:05-14:50",
            "14:55-15:40"
        ]
        
        if period < times.count {
            return times[period]
        }
        return ""
    }
    
    private func isCurrentLesson(period: Int) -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentTime)
        let minute = calendar.component(.minute, from: currentTime)
        
        // Schulzeiten-Mapping
        let lessonTimes = [
            (8, 0, 8, 45),   // 1. Stunde
            (8, 50, 9, 35),  // 2. Stunde
            (9, 40, 10, 25), // 3. Stunde
            (10, 45, 11, 30),// 4. Stunde
            (11, 35, 12, 20),// 5. Stunde
            (12, 25, 13, 10),// 6. Stunde
            (13, 15, 14, 0), // 7. Stunde
            (14, 5, 14, 50), // 8. Stunde
            (14, 55, 15, 40) // 9. Stunde
        ]
        
        guard period < lessonTimes.count else { return false }
        
        let (startHour, startMin, endHour, endMin) = lessonTimes[period]
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

// MARK: - Timeline Skeleton View
struct TimelineSkeletonView: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(0..<6) { _ in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.gray.opacity(0.2))
                        .frame(width: 100, height: 80)
                }
            }
        }
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
                    .font(.title3)
                
                Text("Wichtig")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(.orange.opacity(0.3), lineWidth: 1)
                )
        )
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundStyle(.red)
                    .font(.title3)
                
                Text("Nächste Klausur")
                    .font(.headline)
                    .fontWeight(.bold)
            }
            
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.red.opacity(0.08))
        )
    }
}

// MARK: - Substitutions Widget
struct SubstitutionsWidget: View {
    let count: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .foregroundStyle(.orange)
                .font(.title2)
            
            Text("\(count)")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Vertretungen")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.orange.opacity(0.1))
        )
    }
}

// MARK: - Quick Action Widget
struct QuickActionWidget: View {
    let icon: String
    let title: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title2)
            
            Spacer()
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 100)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(color.opacity(0.1))
        )
    }
}

#Preview {
    HomeView()
}
