//
//  HolidaysEndpoint.swift
//  EffnerApp
//
//  Created by Luis Bros on 07.12.25.
//
import Foundation

struct HolidaysEndpoint : Endpoint {
    
    var baseURL: URL {
        URL(string: "https://www.mehr-schulferien.de")!
    }
    
    var path: String {
        "/api/v2.1/federal-states/bayern/periods"
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
        [
            "start_date": "2025-10-01",
            "end_date": "2026-10-01",
            "type": "vacation"
        ]
    }
    
}
