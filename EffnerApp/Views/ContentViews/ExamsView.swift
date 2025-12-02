//
//  ExamsView.swift
//  EffnerApp
//
//  Created by Luis Bros on 12.08.25.
//

import SwiftUI
import Combine

struct ExamsView: View {
    @EnvironmentObject private var examsCache: ExamsCache

    init(isPreview: Bool = false) {
        if isPreview {
            ExamsCache.shared.saveExams(MockExam.mockExams)
        }
    }

    var body: some View {
        BaseContentView(
            cache: examsCache,
            navigationTitle: "Klausuren",
            errorTitle: "Klausuren nicht verfügbar",
            errorDescription: "Die Klausuren konnten nicht geladen werden. Bitte versuche es später erneut.",
            useScrollViewReader: true,
            scrollToId: { _ in "futureExams" },
            content: { cache in
                if let examResponse = cache.cachedExamResponse {
                    List {
                        Section(header: SeparatorView()) {
                            ForEach(examResponse.exams.filter { isPastExam($0) }, id: \.id) { exam in
                                ExamRowView(exam: exam)
                                    .listRowBackground(Color(UIColor.secondarySystemBackground))
                            }
                        }
                        .id("pastExams")
                        
                        Section(header: SeparatorView(isPast: false)) {
                            ForEach(examResponse.exams.filter { !isPastExam($0) }, id: \.id) { exam in
                                ExamRowView(exam: exam)
                                    .listRowBackground(Color(UIColor.secondarySystemBackground))
                            }
                        }
                        .id("futureExams")
                    }
                    .scrollContentBackground(.hidden)
                    .background(Color(UIColor.systemBackground))
                }
            },
            skeletonView: {
                ExamSkeletonView()
            }
        )
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
    }
}

#Preview {
    ExamsView(isPreview: true)
        .environmentObject(UserSession.shared)
        .environmentObject(ClassesCache.shared)
        .environmentObject(ExamsCache.shared)
}
