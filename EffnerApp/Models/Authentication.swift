//
//  Authentication.swift
//  EffnerApp
//
//  Created by Luis Bros on 21.07.25.
//

import Foundation
import CommonCrypto

struct Authentication: Codable {
    let time: String
    let credentialHash: String
}

extension Authentication {
    init(user: User) {
        self.init(id: user.id, password: user.password)
    }
    
    init(id: String, password: String) {
        let currentTime = String(Int(Date().timeIntervalSince1970 * 1000))
        time = currentTime
        let credentials = "\(id):\(password):\(currentTime)"
        self.credentialHash = sha512(string: credentials)
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
