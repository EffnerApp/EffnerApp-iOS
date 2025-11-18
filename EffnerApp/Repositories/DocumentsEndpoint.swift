//
//  DocumentsEndpoint.swift
//  EffnerApp
//
//  Created by Luis Bros on 18.11.25.
//

import Foundation

struct DocumentsEndpoint : Endpoint {
    
    var baseURL: URL {
        URL(string: Constants.baseURL)!
    }
    
    var path: String {
        "/documents"
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
