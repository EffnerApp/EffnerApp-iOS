//
//  Holiday.swift
//  EffnerApp
//
//  Created by Luis Bros on 07.12.25.
//

import Foundation

// MARK: - Holiday
struct Holiday: Codable, Identifiable {
    var id: String { "\(name)-\(startsOn)" }
    let name: String
    let startsOn: String
    let endsOn: String
    
    enum CodingKeys: String, CodingKey {
        case name
        case startsOn = "starts_on"
        case endsOn = "ends_on"
    }
}
