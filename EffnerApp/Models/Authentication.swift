//
//  Authentication.swift
//  EffnerApp
//
//  Created by Luis Bros on 21.07.25.
//

import Foundation
import CommonCrypto

enum AuthenticationType: Codable {
    case effner  // Original SHA512-based authentication
    case ssbBasic  // HTTP Basic authentication for SSB backend
    case ssbToken  // Token-based authentication for SSB backend
}

struct Authentication: Codable {
    let time: String
    let username: String?
    let credential: String
    let type: AuthenticationType
}

// MARK: - Original Custom Authentication
extension Authentication {
    init(user: User) {
        self.init(username: user.username, password: user.password)
    }
    
    init(username: String, password: String) {
        let currentTime = String(Int(Date().timeIntervalSince1970 * 1000))
        time = currentTime
        let credentials = "\(username):\(password):\(currentTime)"
        self.username = ""
        self.credential = sha512(string: credentials)
        self.type = .effner
    }
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

private func sha512(string: String) -> String {
    guard let data = string.data(using: .utf8) else { return "" }
    var hash = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
    data.withUnsafeBytes {
        _ = CC_SHA512($0.baseAddress, CC_LONG(data.count), &hash)
    }
    return hash.map { String(format: "%02x", $0) }.joined()
}
