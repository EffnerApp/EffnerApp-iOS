//
//  GetUserEndpoint.swift
//  EffnerApp
//
//  Created by Luis Bros on 01.04.26.
//

import Foundation

struct GetUserEndpoint: Endpoint {
    let userId: String
    let auth: Authentication
    
    var baseURL: URL {
        URL(string: Constants.ssbURL)!
    }
    
    var path: String {
        "/users/\(userId)"
    }
    
    var method: HTTPMethod {
        .get
    }
    
    var authentication: Authentication? {
        auth
    }
    
    var headers: [String: String]? {
        nil
    }
    
    var parameters: [String: Any]? {
        nil
    }
}
