//
//  NetworkError.swift
//  EffnerApp
//
//  Created by Luis Bros on 21.07.25.
//
import Foundation

enum NetworkError: Error {
    case invalidResponse(req: URLRequest? = nil, msg: String = "None")
    case decodingFailed(req: URLRequest? = nil, msg: String = "None")
    case clientError(req: URLRequest? = nil, statusCode: Int, msg: String = "None")
    case serverError(req: URLRequest? = nil, statusCode: Int, msg: String = "None")
    case unknownError(req: URLRequest? = nil, statusCode: Int, msg: String = "None")
}

extension NetworkError: LocalizedError {
    var request: URLRequest? {
        Mirror(reflecting: self).children.first?.value as? URLRequest
    }
    var errorDescription: String? {
        let source = Thread.callStackSymbols.first ?? "Unknown Source"
        let req = request?.debugDescription ?? "Unknown Request"
        print("NetworkError: \(self) | Request: \(req) | Source: \(source)")
        switch self {
            case .invalidResponse(_, let message):
                return "Invalid response received from the server. Message: \(message)"
            case .decodingFailed(_, let message):
                return "Failed to decode the response data. Message: \(message)"
            case .clientError(_, let statusCode, let message):
                return "Client error occurred. Status code: \(statusCode) Message: \(message)"
            case .serverError(_, let statusCode, let message):
                return "Server error occurred. Status code: \(statusCode) Message: \(message)"
            case .unknownError(_, let statusCode, let message):
                return "An unknown error occurred. Status code: \(statusCode) Message: \(message)"
        }
    }
}
