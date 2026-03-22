//
//  ExamsEndpoint.swift
//  EffnerApp
//
//  Created by Luis Bros on 12.08.25.
//
import Foundation

struct ExamsEndpoint : Endpoint {
    
    var baseURL: URL {
        URL(string: Constants.ssbURL)!
    }
    
    var path: String {
        "/exams/class/" + (UserSession.shared.user!.primaryClass ?? "")
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
