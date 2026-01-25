//
//  UpdateKlassesEndpoint.swift
//  EffnerApp
//
//  Created by Luis Bros on 25.01.26.
//

//
//  DeleteUserEndpoint.swift
//  EffnerApp
//
//  Created by Luis Bros on 25.01.26.
//

import Foundation

struct UpdateKlassesEndpoint : Endpoint {
    let klasses: [String]
    
    var baseURL: URL {
        URL(string: Constants.ssbURL)!
    }
    
    var path: String {
        "/users/\(UserSession.shared.user!.ssbId)/classes"
    }
    
    var method: HTTPMethod {
        .put
    }
    
    var authentication: Authentication? {
        UserSession.shared.user!.generateSSBTokenAuth()
    }
    
    var headers: [String : String]? {
        nil
    }
    
    var parameters: [String: Any]? {
        nil
    }
    
    var body: Encodable? {
        return klasses
    }
    
}
