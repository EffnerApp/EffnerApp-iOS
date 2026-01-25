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
    var body: Encodable? { get }
}

extension Endpoint {
    func urlRequest() throws -> URLRequest {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        var allHeaders = headers ?? [:]
        allHeaders["User-Agent"] = "EffnerApp/8.0-iOS"
        allHeaders["Content-Type"] = "application/json"
        
        if let auth = authentication {
            switch auth.type {
            case .effner, .ssbBasic:
                allHeaders["Authorization"] = "Basic \(auth.credential)"
                allHeaders["X-Time"] = auth.time
            case .ssbToken:
                allHeaders["X-User-Id"] = auth.username
                allHeaders["X-User-Token"] = auth.credential
            }
        }
        
        request.allHTTPHeaderFields = allHeaders
        
        if let parameters = parameters {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
            request.url = components?.url
        }
        
        if let body = body {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            request.httpBody = try encoder.encode(body)
        }
        
        return request
    }
    
    // default body implementation
    var body: Encodable? {
        nil
    }
    
}
