//
//  NetworkingManager.swift
//  EffnerApp
//
//  Created by Luis Bros on 21.07.25.
//

import Foundation
import OSLog

extension Notification.Name {
    static let userUnauthorized = Notification.Name("userUnauthorized")
}

protocol NetworkManaging {
    func fetch<T: Decodable>(from endpoint: Endpoint) async throws -> T
}

final class NetworkManager: NetworkManaging {
    private static let logger = Log.networking
    static var shared = NetworkManager()
    private let session: URLSession
    
    init(session: URLSession = .shared) {
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
            Self.logger.debug("Response: \(String(data: data, encoding: .utf8) ?? "<non-UTF8 data>", privacy: .private)")
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        } catch {
            Self.logger.error("Decoding error: \(error)")
            throw NetworkError.decodingFailed(req: request)
        }
    }
    
    private func validateResponse(_ request: URLRequest, _ response: HTTPURLResponse) throws {
        switch response.statusCode {
        case 200...299:
            return
        case 400...499:
            if (response.statusCode == 401 || response.statusCode == 403),
               request.value(forHTTPHeaderField: "X-User-Id") != nil {
                NotificationCenter.default.post(name: .userUnauthorized, object: nil)
            }
            throw NetworkError.clientError(req: request, statusCode: response.statusCode)
        case 500...599:
            throw NetworkError.serverError(req: request, statusCode: response.statusCode)
        default:
            throw NetworkError.unknownError(req: request, statusCode: response.statusCode)
        }
    }
}
