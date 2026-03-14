//
//  ExamsEndpoint.swift
//  EffnerApp
//
//  Created by Luis Bros on 12.08.25.
//
import Foundation

struct ExamsEndpoint : Endpoint {
    
    var baseURL: URL {
        URL(string: Constants.baseURL)!
    }
    
    var path: String {
        var klass = UserSession.shared.user!.primaryClass!
        if (klass.starts(with: "12") || klass.starts(with: "13")) {
            klass = String(klass.prefix(2))
        }
        return "/exams/" + klass
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
