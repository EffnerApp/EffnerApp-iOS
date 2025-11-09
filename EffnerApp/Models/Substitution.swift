//
//  Substitution.swift
//  EffnerApp
//
//  Created by Luis Bros on 08.11.25.
//

import Foundation

struct SubstitutionResponse: Codable {
    let plans: [SubstitutionPlan]
    
    enum CodingKeys: String, CodingKey {
        case plans = "plans"
    }
    
    init(plans: [SubstitutionPlan]) {
        self.plans = plans
    }
}

// MARK: - Substitution Plan
struct SubstitutionPlan: Codable, Identifiable {
    var id: String { hash }
    let date: String
    let absent: [Absent]
    let hash: String
    let title: String
    let infos: [String]?
    let substitutions: [Substitution]?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case date
        case absent
        case hash
        case title
        case infos
        case substitutions
        case createdAt = "created_at"
    }
    
    init(date: String, absent: [Absent], hash: String, title: String, infos: [String]?, substitutions: [Substitution]?, createdAt: Date) {
        self.date = date
        self.absent = absent
        self.hash = hash
        self.title = title
        self.infos = infos
        self.substitutions = substitutions
        self.createdAt = createdAt
    }
}

// MARK: - Absent Teacher
struct Absent: Codable, Identifiable {
    var id: String { className + periods }
    let className: String
    let periods: String
    
    enum CodingKeys: String, CodingKey {
        case className = "class"
        case periods
    }
    
    init(className: String, periods: String) {
        self.className = className
        self.periods = periods
    }
}

// MARK: - Substitution
struct Substitution: Codable, Identifiable {
    var id: String { "\(period)-\(teacher ?? "")-\(substitute ?? "")-\(room ?? "")" }
    let period: String
    let teacher: String?
    let substitute: String?
    let room: String?
    let info: String?
    
    enum CodingKeys: String, CodingKey {
        case period
        case teacher
        case substitute
        case room
        case info
    }
    
    init(period: String, teacher: String?, substitute: String?, room: String?, info: String?) {
        self.period = period
        self.teacher = teacher
        self.substitute = substitute
        self.room = room
        self.info = info
    }
}
