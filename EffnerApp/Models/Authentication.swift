//
//  Authentication.swift
//  EffnerApp
//
//  Created by Luis Bros on 21.07.25.
//

import Foundation

enum AuthenticationType: Codable {
    case ssbBasic  // HTTP Basic authentication for SSB backend
    case ssbToken  // Token-based authentication for SSB backend
}

struct Authentication: Codable {
    let time: String
    let username: String?
    let credential: String
    let type: AuthenticationType
}

// MARK: - SSB Basic Authentication
extension Authentication {
    /// Creates SSB authentication using HTTP Basic authentication format
    /// - Parameters:
    ///   - username: The username (e.g., "1")
    ///   - password: The password (e.g., "1234")
    /// - Returns: Authentication instance with Base64-encoded credentials
    static func ssbBasic(username: String, password: String) -> Authentication {
        let currentTime = String(Int(Date().timeIntervalSince1970 * 1000))
        let credentials = "\(username):\(password)"
        let credentialData = credentials.data(using: .utf8)!
        let base64Credentials = credentialData.base64EncodedString()
        
        return Authentication(
            time: currentTime,
            username: "", // SSB Basic doesnt use username field. Set empty to avoid confusion.
            credential: base64Credentials,
            type: .ssbBasic
        )
    }
    
    /// Creates SSB authentication using token-based format
    /// - Parameters:
    ///   - id: the ssb user account id
    ///   - token: the ssb authentication token
    /// - Returns: Authentication instance with the provided token
    static func ssbToken(id: String, token: String) -> Authentication {
        let currentTime = String(Int(Date().timeIntervalSince1970 * 1000))
        return Authentication(
            time: currentTime,
            username: id,
            credential: token,
            type: .ssbToken
        )
    }

}
