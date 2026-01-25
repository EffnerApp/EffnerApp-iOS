//
//  DeleteUserEndpoint.swift
//  EffnerApp
//
//  Created by Luis Bros on 25.01.26.
//

import Foundation

struct DeleteUserEndpoint : Endpoint {
    
    var baseURL: URL {
        URL(string: Constants.ssbURL)!
    }
    
    var path: String {
        "/users"
    }
    
    var method: HTTPMethod {
        .delete
    }
    
    var authentication: Authentication? {
        UserSession.shared.user!.generateSSBTokenAuth()
    }
    
    var headers: [String : String]? {
        nil
    }
    
    var parameters: [String: Any]? {
        nil
    }
    
}
