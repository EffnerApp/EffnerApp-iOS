//
//  ExamMock.swift
//  EffnerApp
//
//  Created by Luis Bros on 31.08.25.
//

import Foundation

struct MockExam {
    public static let mockExams: ExamsResponse = ExamsResponse(
        className: "test",
        exams: [
            Exam(id: "1", date: "01.08.2025", date2: nil, name: "Mathematik", course: "Mathe 101"),
            Exam(id: "2", date: "15.09.2025", date2: nil, name: "Physik", course: "Physik 202"),
            Exam(id: "3", date: "01.10.2025", date2: nil, name: "Chemie", course: "Chemie 303"),
            Exam(id: "4", date: "15.07.2025", date2: nil, name: "Biologie", course: "Bio 404"),
            Exam(id: "5", date: "30.06.2025", date2: nil, name: "Informatik", course: "Informatik 505"),
            Exam(id: "6", date: "20.12.2025", date2: nil, name: "Geschichte", course: "Geschichte 606"),
            Exam(id: "7", date: "10.11.2025", date2: nil, name: "Geographie", course: "Geo 707"),
            Exam(id: "8", date: "05.05.2025", date2: nil, name: "Englisch", course: "Englisch 808"),
            Exam(id: "9", date: "25.04.2025", date2: nil, name: "Deutsch", course: "Deutsch 909"),
            Exam(id: "10", date: "12.03.2025", date2: nil, name: "Kunst", course: "Kunst 010"),
            Exam(id: "11", date: "18.02.2025", date2: nil, name: "Musik", course: "Musik 111")
        ]
    )
}
