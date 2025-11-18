//
//  ConfigEndpoint.swift
//  EffnerApp
//
//  Created by Luis Bros on 18.11.25.
//
import Foundation

struct ConfigEndpoint : Endpoint {
    
    var baseURL: URL {
        URL(string: Constants.baseURL)!
    }
    
    var path: String {
        "/config/" + UserSession.shared.user!.klass
    }
    
    var method: HTTPMethod {
        .get
    }
    
    var authentication: Authentication? {
        UserSession.shared.user!.generateAuth()
    }
    
    var headers: [String : String]? {
        nil
    }
    
    var parameters: [String : Any]? {
        nil
    }
    
}
