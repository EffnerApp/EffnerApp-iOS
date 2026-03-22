//
//  ExamsResponse.swift
//  EffnerApp
//
//  Created by Luis Bros on 12.08.25.
//

import Foundation

struct ExamsResponse: Codable {
    let exams: [Exam]

    init(exams: [Exam]) {
        self.exams = exams
    }
}

struct Exam: Codable, Identifiable {
    let dateFrom: String
    let dateTo: String?
    let description: String
    let subject: String?
    let examType: String?

    var id: String {
        "\(dateFrom)-\(description)"
    }

    init(dateFrom: String, dateTo: String? = nil, description: String, subject: String? = nil, examType: String? = nil) {
        self.dateFrom = dateFrom
        self.dateTo = dateTo
        self.description = description
        self.subject = subject
        self.examType = examType
    }
}
