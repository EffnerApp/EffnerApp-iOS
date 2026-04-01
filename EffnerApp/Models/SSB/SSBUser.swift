//
//  SSBUser.swift
//  EffnerApp
//
//  Created by Luis Bros on 25.01.26.
//

import Foundation

struct SSBUserRequest: Codable {
    let deviceToken: String?
    let classes: [String]
}

struct SSBUserResponse: Codable, Identifiable {
    let id: String
    let token: String?
    let deviceToken: String?
    let classes: [String]
}
