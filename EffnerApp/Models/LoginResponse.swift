//
//  LoginResponse.swift
//  EffnerApp
//
//  Created by Luis Bros on 21.07.25.
//

import Foundation

struct LoginResponse: Codable {
    var status: Status
    
    struct Status: Codable {
        var login: Bool
    }

}


