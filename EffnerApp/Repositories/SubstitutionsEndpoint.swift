//
//  SubstitutionsEndpoint.swift
//  EffnerApp
//
//  Created by Luis Bros on 08.11.25.
//

import Foundation

struct SubstitutionsEndpoint : Endpoint {
    
    var baseURL: URL {
        URL(string: Constants.v4URL)!
    }
    
    var path: String {
        "/substitutions/get/" + UserSession.shared.user!.klass
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
