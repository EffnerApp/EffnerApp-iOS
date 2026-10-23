//
//  NetworkError.swift
//  EffnerApp
//
//  Created by Luis Bros on 21.07.25.
//
import Foundation
import OSLog

enum NetworkError: Error {
    case invalidResponse(req: URLRequest? = nil, msg: String = "None")
    case decodingFailed(req: URLRequest? = nil, msg: String = "None")
    case clientError(req: URLRequest? = nil, statusCode: Int, msg: String = "None")
    case serverError(req: URLRequest? = nil, statusCode: Int, msg: String = "None")
    case unknownError(req: URLRequest? = nil, statusCode: Int, msg: String = "None")
}

extension NetworkError: LocalizedError {
    private static let logger = Log.networking
    var request: URLRequest? {
        Mirror(reflecting: self).children.first?.value as? URLRequest
    }
    var errorDescription: String? {
        let source = Thread.callStackSymbols.first ?? "Unknown Source"
        let req = request?.debugDescription ?? "Unknown Request"
        Self.logger.error("NetworkError: \(String(describing: self)) | Request: \(req) | Source: \(source)")
        switch self {
            case .invalidResponse(_, let message):
                return "Invalid response received from the server. Message: \(message)"
            case .decodingFailed(_, let message):
                return "Failed to decode the response data. Message: \(message)"
            case .clientError(_, let statusCode, let message):
                if statusCode == 401 || statusCode == 403 {
                    return "Account ID oder Passwort ist nicht korrekt."
                }
                if statusCode == 429 {
                    return "Du hast in der letzten Minute zu viele Anfragen gestellt. Bitte warte einen Moment, bevor du es erneut versuchst."
                }
                return message != "None" ? message : "Client error occurred. Status code: \(statusCode) Message: \(message)"
            case .serverError(_, let statusCode, let message):
                return message != "None" ? message : "Der Server ist momentan nicht erreichbar. Bitte versuche es später erneut. (\(statusCode))"
            case .unknownError(_, let statusCode, let message):
                if statusCode == 0 {
                    return "Keine Verbindung zum Server möglich. Bitte überprüfe deine Internetverbindung."
                }
                return "An unknown error occurred. Status code: \(statusCode) Message: \(message)"
        }
    }
}
