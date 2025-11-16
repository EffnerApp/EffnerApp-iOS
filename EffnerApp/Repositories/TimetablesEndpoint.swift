//
//  TimetablesEndpoint.swift
//  EffnerApp
//
//  Created by Luis Bros on 16.11.25.
//
import Foundation

struct TimetablesEndpoint : Endpoint {
    
    var baseURL: URL {
        URL(string: Constants.baseURL)!
    }
    
    var path: String {
        "/timetables/" + UserSession.shared.user!.klass
    }
    
    var method: HTTPMethod {
        .post
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
