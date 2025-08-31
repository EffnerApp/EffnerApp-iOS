//
//  ExamsResponse.swift
//  EffnerApp
//
//  Created by Luis Bros on 12.08.25.
//

import Foundation

struct ExamsResponse: Codable, Identifiable {
    let id: String?
    let className: String
    let v: Int?
    let createdAt: String?
    let exams: [Exam]
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case className = "class"
        case v = "__v"
        case createdAt
        case exams
        case updatedAt
    }

    init(id: String? = nil, className: String, v: Int? = nil, createdAt: String? = nil, exams: [Exam], updatedAt: String? = nil) {
        self.id = id
        self.className = className
        self.v = v
        self.createdAt = createdAt
        self.exams = exams
        self.updatedAt = updatedAt
    }
}

struct Exam: Codable, Identifiable {
    let id: String
    let date: String
    let date2: String?
    let name: String
    let course: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case date
        case date2
        case name
        case course
    }

    init(id: String, date: String, date2: String? = nil, name: String, course: String? = nil) {
        self.id = id
        self.date = date
        self.date2 = date2
        self.name = name
        self.course = course
    }
}
