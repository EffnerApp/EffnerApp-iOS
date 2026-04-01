//
//  TimetablesEndpoint.swift
//  EffnerApp
//
//  Created by Luis Bros on 16.11.25.
//
import Foundation

struct TimetablesEndpoint : Endpoint {
    
    var baseURL: URL {
        URL(string: Constants.ssbURL)!
    }
    
    var path: String {
        "/timetables/class/" + (UserSession.shared.user!.primaryClass ?? "")
    }
    
    var method: HTTPMethod {
        .get
    }
    
    var authentication: Authentication? {
        UserSession.shared.user!.generateSSBTokenAuth()
    }
    
    var headers: [String : String]? {
        nil
    }
    
    var parameters: [String : Any]? {
        nil
    }
    
}
