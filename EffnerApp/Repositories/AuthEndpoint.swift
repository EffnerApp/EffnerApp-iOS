//
//  AuthenticationEndpoint.swift
//  EffnerApp
//
//  Created by Luis Bros on 21.07.25.
//
import Foundation

struct AuthEndpoint : Endpoint {
    let auth: Authentication
    
    var baseURL: URL {
        URL(string: Constants.baseURL)!
    }
    
    var path: String {
        "/auth/login"
    }
    
    var method: HTTPMethod {
        .post
    }
    
    var authentication: Authentication? {
        auth
    }
    
    var headers: [String : String]? {
        nil            
    }
    
    var parameters: [String : Any]? {
        nil
    }
    
}
