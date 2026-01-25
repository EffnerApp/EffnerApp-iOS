//
//  CreateUserEndpoint.swift
//  EffnerApp
//
//  Created by Luis Bros on 25.01.26.
//

import Foundation

struct CreateUserEndpoint : Endpoint {
    let ssbUserRequest: SSBUserRequest
    
    var baseURL: URL {
        URL(string: Constants.ssbURL)!
    }
    
    var path: String {
        "/users"
    }
    
    var method: HTTPMethod {
        .post
    }
    
    var authentication: Authentication? {
        UserSession.shared.user!.generateSSBBasicAuth()
    }
    
    var headers: [String : String]? {
        nil
    }
    
    var parameters: [String: Any]? {
        nil
    }
    
    var body: Encodable? {
        ssbUserRequest
    }
    
}
