//
//  ClassesEndpoint.swift
//  EffnerApp
//
//  Created by Luis Bros on 21.07.25.
//

import Foundation

struct ClassesEndpoint : Endpoint {
    
    var baseURL: URL {
        URL(string: Constants.ssbURL)!
    }
    
    var path: String {
        "/classes"
    }
    
    var method: HTTPMethod {
        .get
    }
    
    var authentication: Authentication? {
        nil
    }
    
    var headers: [String : String]? {
        nil
    }
    
    var parameters: [String : Any]? {
        nil
    }
    
}
