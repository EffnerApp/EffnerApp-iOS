//
//  ExamMock.swift
//  EffnerApp
//
//  Created by Luis Bros on 31.08.25.
//

import Foundation

struct MockExam {
    public static let mockExams: ExamsResponse = ExamsResponse(
        exams: [
            Exam(dateFrom: "2025-10-01", description: "angek. Extemporale in Mathematik", subject: "Mathematik", examType: "EXTEMPORALE"),
            Exam(dateFrom: "2025-10-09", description: "Extemporale in Wirtschaft und Recht", subject: "Wirtschaft und Recht", examType: "EXTEMPORALE"),
            Exam(dateFrom: "2025-11-13", description: "Schulaufgabe in Deutsch", subject: "Deutsch", examType: "SCHULAUFGABE"),
            Exam(dateFrom: "2025-11-27", description: "Schulaufgabe in Mathematik", subject: "Mathematik", examType: "SCHULAUFGABE"),
            Exam(dateFrom: "2025-12-15", dateTo: "2025-12-19", description: "Weihnachtsfrieden"),
            Exam(dateFrom: "2026-01-15", description: "Extemporale in Mathematik", subject: "Mathematik", examType: "EXTEMPORALE"),
            Exam(dateFrom: "2026-02-05", description: "Schulaufgabe in Mathematik", subject: "Mathematik", examType: "SCHULAUFGABE"),
            Exam(dateFrom: "2026-03-04", description: "mündl. Schulaufgabe in Englisch", subject: "Englisch", examType: "ORAL"),
            Exam(dateFrom: "2026-03-25", description: "Schulaufgabe in Latein", subject: "Latein", examType: "SCHULAUFGABE"),
            Exam(dateFrom: "2026-05-07", description: "Schulaufgabe in Mathematik", subject: "Mathematik", examType: "SCHULAUFGABE"),
            Exam(dateFrom: "2026-06-17", description: "Schulaufgabe in Englisch", subject: "Englisch", examType: "SCHULAUFGABE")
        ]
    )
}
