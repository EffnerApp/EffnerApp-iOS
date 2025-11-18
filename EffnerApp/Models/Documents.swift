//
//  Documents.swift
//  EffnerApp
//
//  Created by Luis Bros on 18.11.25.
//

import Foundation

// MARK: - DocumentsResponse
typealias DocumentsResponse = [Document]

// MARK: - Document
struct Document: Codable, Identifiable {
    let id: String
    let key: String
    let uri: String
    let `static`: Bool
    let name: String?
    let createdAt: Date?
    let updatedAt: Date?
    let v: Int?
    
    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case key
        case uri
        case `static`
        case name
        case createdAt
        case updatedAt
        case v = "__v"
    }
    
    // Memberwise initializer for manual creation
    init(id: String, key: String, uri: String, static: Bool, name: String?, createdAt: Date?, updatedAt: Date?, v: Int?) {
        self.id = id
        self.key = key
        self.uri = uri
        self.`static` = `static`
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.v = v
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        key = try container.decode(String.self, forKey: .key)
        uri = try container.decode(String.self, forKey: .uri)
        `static` = try container.decode(Bool.self, forKey: .static)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        v = try container.decodeIfPresent(Int.self, forKey: .v)
        
        // ISO8601-Datum-Decoder für createdAt und updatedAt
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let createdAtString = try container.decodeIfPresent(String.self, forKey: .createdAt) {
            createdAt = dateFormatter.date(from: createdAtString)
        } else {
            createdAt = nil
        }
        
        if let updatedAtString = try container.decodeIfPresent(String.self, forKey: .updatedAt) {
            updatedAt = dateFormatter.date(from: updatedAtString)
        } else {
            updatedAt = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(key, forKey: .key)
        try container.encode(uri, forKey: .uri)
        try container.encode(`static`, forKey: .static)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(v, forKey: .v)
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let createdAt = createdAt {
            try container.encode(dateFormatter.string(from: createdAt), forKey: .createdAt)
        }
        
        if let updatedAt = updatedAt {
            try container.encode(dateFormatter.string(from: updatedAt), forKey: .updatedAt)
        }
    }
}
