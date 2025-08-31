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
        "/exams/" + UserSession.shared.user!.classA
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
