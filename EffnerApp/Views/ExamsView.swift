//
//  ExamsView.swift
//  EffnerApp
//
//  Created by Luis Bros on 12.08.25.
//

import SwiftUI
import Combine

struct ExamsView: View {
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil
    @EnvironmentObject private var examsCache: ExamsCache

    init(isPreview: Bool = false) {
        if isPreview {
            ExamsCache.shared.saveExams(MockExam.mockExams)
        }
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                Group {
                    if examsCache.hasError {
                        ContentUnavailableView(
                            "Klausuren nicht verfügbar",
                            systemImage: "calendar.badge.exclamationmark",
                            description: Text("Die Klausuren konnten nicht geladen werden. Bitte versuche es später erneut.")
                        )
                    } else if examsCache.cachedExamResponse.exams.isEmpty {
                        List(0..<10, id: \.self) { _ in
                            ExamSkeletonView()
                        }
                        .redacted(reason: .placeholder)
                    } else {
                        List {
                            Section(header: SeparatorView()) {
                                ForEach(examsCache.cachedExamResponse.exams.filter { isPastExam($0) }, id: \.id) { exam in
                                    ExamRowView(exam: exam)
                                }
                            }
                            .id("pastExams")
                            
                            Section(header: SeparatorView(isPast: false)) {
                                ForEach(examsCache.cachedExamResponse.exams.filter { !isPastExam($0) }, id: \.id) { exam in
                                    ExamRowView(exam: exam)
                                }
                                .id("futureExams")
                            }
                        }
                    }
                }
                .onAppear {
                    proxy.scrollTo("futureExams", anchor: .top)
                }
                .navigationTitle("Klausuren")
                .toolbarTitleDisplayMode(.inlineLarge)
                .toolbar {
                    ToolbarComponent()
                }
            }
        }
    }

    private func isPastExam(_ exam: Exam) -> Bool {
        let isoFormatter = ISO8601DateFormatter()
        let germanFormatter = DateFormatter()
        germanFormatter.dateFormat = "dd.MM.yyyy"

        if let examDate = isoFormatter.date(from: exam.date) ?? germanFormatter.date(from: exam.date) {
            return examDate < Date()
        }
        return false
    }
}

struct ExamRowView: View {
    let exam: Exam
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .center, spacing: 0) {
                Text(DateFormatterUtil.formatToShortDate(exam.date).components(separatedBy: " ")[0])
                    .font(.title2)
                Text(DateFormatterUtil.formatToShortDate(exam.date).components(separatedBy: " ")[1])
                    .font(.system(size: 17))
            }
            .frame(alignment: .center)

            VStack(alignment: .leading, spacing: 0) {
                Text(exam.name)
                    .font(.title2)
                    .padding(.leading, 12)

                HStack {
                    if let examDate2 = exam.date2 {
                        Text("bis \(DateFormatterUtil.formatToShortDate(examDate2))")
                            .font(.subheadline)
                    }
                    if let course = exam.course {
                        Text("Kurs: \(course)")
                            .font(.subheadline)
                    }
                }.padding(.leading, 12)
            }
        }
        .padding(.vertical, 0)
        .padding(.horizontal, 12)
    }
}



struct SeparatorView: View {
    var isPast: Bool = true

    var body: some View {
        HStack {
            if isPast {
                Text("Vergangene Klausuren")
                    .font(.headline)
            } else {
                Text("Zukünftige Klausuren")
                    .font(.headline)
            }
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemGroupedBackground))
    }
}

#Preview {
    ExamsView(isPreview: true)
}
