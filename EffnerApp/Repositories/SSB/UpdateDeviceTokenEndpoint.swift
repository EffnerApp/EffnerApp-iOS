//
//  UpdateDeviceTokenEndpoint.swift
//  EffnerApp
//
//  Created by Luis Bros on 01.04.26.
//

import Foundation

struct UpdateDeviceTokenEndpoint: Endpoint {
    let deviceToken: String?
    
    var baseURL: URL {
        URL(string: Constants.ssbURL)!
    }
    
    var path: String {
        "/users/\(UserSession.shared.user?.ssbId ?? "")/device-token"
    }
    
    var method: HTTPMethod {
        .put
    }
    
    var authentication: Authentication? {
        UserSession.shared.user?.generateSSBTokenAuth()
    }
    
    var headers: [String : String]? {
        nil
    }
    
    var parameters: [String: Any]? {
        nil
    }
    
    var body: Encodable? {
        return ["deviceToken": deviceToken]
    }
    
}
