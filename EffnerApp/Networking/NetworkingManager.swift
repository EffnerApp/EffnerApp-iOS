//
//  NetworkingManager.swift
//  EffnerApp
//
//  Created by Luis Bros on 21.07.25.
//

import Foundation

protocol NetworkManaging {
    func fetch<T: Decodable>(from endpoint: Endpoint) async throws -> T
}

final class NetworkManager: NetworkManaging {
    static let shared = NetworkManager()
    private let session: URLSession
    
    private init(session: URLSession = .shared) {
        self.session = session
    }
    
    func fetch<T: Decodable>(from endpoint: Endpoint) async throws -> T {
        let request = try endpoint.urlRequest()
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse(req: request)
        }
        
        try validateResponse(request, httpResponse)
        
        do {
            print(String(data: data, encoding: .utf8) ?? "<non-UTF8 data>")
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingFailed(req: request)
        }
    }
    
    private func validateResponse(_ request: URLRequest, _ response: HTTPURLResponse) throws {
        switch response.statusCode {
        case 200...299:
            return
        case 400...499:
            throw NetworkError.clientError(req: request, statusCode: response.statusCode)
        case 500...599:
            throw NetworkError.serverError(req: request, statusCode: response.statusCode)
        default:
            throw NetworkError.unknownError(req: request, statusCode: response.statusCode)
        }
    }
}
