//
//  Authentication.swift
//  EffnerApp
//
//  Created by Luis Bros on 21.07.25.
//

import Foundation
import CommonCrypto

enum AuthenticationType: Codable {
    case custom  // Original SHA512-based authentication
    case ssbBasic  // HTTP Basic authentication for SSB backend
}

struct Authentication: Codable {
    let time: String
    let credentialHash: String
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
        self.credentialHash = sha512(string: credentials)
        self.type = .custom
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
            time: currentTime,  // SSB Basic auth doesn't use time
            credentialHash: base64Credentials,
            type: .ssbBasic
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
