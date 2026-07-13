//
//  Substitution.swift
//  EffnerApp
//
//  Created by Luis Bros on 08.11.25.
//

import Foundation

// The SSB API returns [SubstitutionPlan] directly.
// SubstitutionResponse wraps this array to keep the cache and view layer consistent.
struct SubstitutionResponse: Codable {
    let plans: [SubstitutionPlan]
    
    init(plans: [SubstitutionPlan]) {
        self.plans = plans
    }
}

// MARK: - Substitution Plan
struct SubstitutionPlan: Codable, Identifiable {
    let id: Int
    let title: String
    let planDate: String
    let createdAt: String
    let infos: [String]
    let absences: [Absence]
    let substitutions: [Substitution]
}

// MARK: - Absence
struct Absence: Codable, Identifiable {
    var id: String { className + periods }
    let className: String
    let periods: String
    
    enum CodingKeys: String, CodingKey {
        case className = "class" //TODO: Change sometime in backend
        case periods
    }
    
    init(className: String, periods: String) {
        self.className = className
        self.periods = periods
    }
}

// MARK: - Substitution
struct Substitution: Codable, Identifiable {
    var id: String { "\(klassName)-\(period)-\(teacher ?? "")-\(substitute ?? "")-\(room ?? "")" }
    let klassName: String
    let teacher: String?
    let substitute: String?
    let period: String
    let room: String?
    let info: String?
    
    init(klassName: String, teacher: String?, substitute: String?, period: String, room: String?, info: String?) {
        self.klassName = klassName
        self.teacher = teacher
        self.substitute = substitute
        self.period = period
        self.room = room
        self.info = info
    }
}
