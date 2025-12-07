//
//  Holiday.swift
//  EffnerApp
//
//  Created by Luis Bros on 07.12.25.
//

import Foundation

// MARK: - HolidayResponse
struct HolidayResponse: Codable {
    let data: [Holiday]
    let meta: Meta
}

// MARK: - Holiday
struct Holiday: Codable, Identifiable {
    let id: Int
    let name: String
    let type: String
    let startsOn: String
    let endsOn: String
    let locationId: Int
    let isPublicHoliday: Bool
    let isSchoolVacation: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case startsOn = "starts_on"
        case endsOn = "ends_on"
        case locationId = "location_id"
        case isPublicHoliday = "is_public_holiday"
        case isSchoolVacation = "is_school_vacation"
    }
}

// MARK: - Meta
struct Meta: Codable {
    let location: Location
    let dateRange: DateRange
    let apiVersion: String
    
    enum CodingKeys: String, CodingKey {
        case location
        case dateRange = "date_range"
        case apiVersion = "api_version"
    }
}

// MARK: - Location
struct Location: Codable {
    let code: String
    let id: Int
    let links: Links
    let name: String
    let type: String
    let slug: String
    let parentLocationId: Int
    
    enum CodingKeys: String, CodingKey {
        case code
        case id
        case links
        case name
        case type
        case slug
        case parentLocationId = "parent_location_id"
    }
}

// MARK: - Links
struct Links: Codable {
    let `self`: String
    let periods: String
    let icalendar: String
}

// MARK: - DateRange
struct DateRange: Codable {
    let startDate: String
    let endDate: String
    
    enum CodingKeys: String, CodingKey {
        case startDate = "start_date"
        case endDate = "end_date"
    }
}

