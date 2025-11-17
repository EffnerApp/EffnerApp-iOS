//
//  Timetable.swift
//  EffnerApp
//
//  Created by Luis Bros on 16.11.25.
//

import Foundation

// MARK: - Timetable Response
struct TimetableResponse: Decodable {
    let data: [Timetable]
    let schedule: [Array<Int>?]
}

// MARK: - Class Timetable
struct Timetable: Decodable {
    let meta: [SubjectMeta]
    let lessons: [[String]]
    let updatedAt: String
    let className: String
    
    enum CodingKeys: String, CodingKey {
        case meta
        case lessons
        case updatedAt
        case className = "class"
    }
}

// MARK: - Subject Meta
struct SubjectMeta: Decodable {
    let subject: String
    let color: String
}

