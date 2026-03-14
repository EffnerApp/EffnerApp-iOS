//
//  SubstitutionsEndpoint.swift
//  EffnerApp
//
//  Created by Luis Bros on 08.11.25.
//

import Foundation

struct SubstitutionsEndpoint : Endpoint {
    
    var baseURL: URL {
        URL(string: Constants.ssbURL)!
    }
    
    var path: String {
        "/substitutions/class/" + (UserSession.shared.user!.primaryClass ?? "") + "/upcoming"
    }
    
    var method: HTTPMethod {
        .get
    }
    
    var authentication: Authentication? {
        UserSession.shared.user!.generateSSBBasicAuth()
    }
    
    var headers: [String : String]? {
        nil
    }
    
    var parameters: [String : Any]? {
        nil
    }
    
}
