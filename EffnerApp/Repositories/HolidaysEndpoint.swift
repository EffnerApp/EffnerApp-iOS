//
//  HolidaysEndpoint.swift
//  EffnerApp
//
//  Created by Luis Bros on 07.12.25.
//
import Foundation

struct HolidaysEndpoint : Endpoint {
    
    var baseURL: URL {
        URL(string: Constants.ssbURL)!
    }
    
    var path: String {
        "/schoolholidays"
    }
    
    var method: HTTPMethod {
        .get
    }
    
    var authentication: Authentication? {
        UserSession.shared.user?.generateSSBTokenAuth()
    }
    
    var headers: [String : String]? {
        nil
    }
    
    var parameters: [String : Any]? {
        nil
    }
    
}
