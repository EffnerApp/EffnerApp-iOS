//
//  Untitled.swift
//  EffnerApp
//
//  Created by Luis Bros on 21.07.25.
//
import Foundation

protocol Endpoint {
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var authentication: Authentication? { get }
    var headers: [String: String]? { get }
    var parameters: [String: Any]? { get }
}

extension Endpoint {
    func urlRequest() throws -> URLRequest {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        var allHeaders = headers ?? [:]
        allHeaders["User-Agent"] = "EffnerApp/8.0-iOS"
        allHeaders["Content-Type"] = "application/json"
        if(authentication != nil) {
            allHeaders["Authorization"] = "Basic \(authentication!.credentialHash)"
            allHeaders["X-Time"] = authentication!.time
            print("Time3: " + authentication!.time)
        }
        request.allHTTPHeaderFields = allHeaders
        
        if let parameters = parameters {
            if method == .get {
                var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                components?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
                request.url = components?.url
            } else {
                request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
            }
        }
        
        return request
    }
}
