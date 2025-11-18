//
//  DocumentsMock.swift
//  EffnerApp
//
//  Created by Luis Bros on 18.11.25.
//

import Foundation

struct DocumentsMock {
    static func mockDocuments() -> DocumentsResponse {
        return [
        Document(
            id: "631f7cbe0707d27577a4111f",
            key: "DATA_FOOD_PLAN",
            uri: "https://campuscafe.online/wp-content/uploads/speiseplaene/MeinCampusCaf%C3%A9_Speiseplan_Mittagsb%C3%BCffet_CampusCaf%C3%A9_Effner.pdf",
            static: true,
            name: nil,
            createdAt: nil,
            updatedAt: nil,
            v: nil
        ),
        Document(
            id: "650da2c9c6f6aec2d78b6ba6",
            key: "DATA_INFORMATION_CAMPUS_CAFE_FOOD_PLAN",
            uri: "https://campuscafe.online/wp-content/uploads/speiseplaene/MeinCampusCaf%C3%A9_Speiseplan_Mittagsb%C3%BCffet_CampusCaf%C3%A9_Effner.pdf",
            static: true,
            name: "CampusCafé - Mittagsbüffet",
            createdAt: ISO8601DateFormatter().date(from: "2023-09-22T16:20:00.000Z"),
            updatedAt: ISO8601DateFormatter().date(from: "2023-09-22T16:20:00.000Z"),
            v: 0
        ),
        Document(
            id: "650da2f2c6f6aec2d78b6ba7",
            key: "DATA_INFORMATION_CAMPUS_CAFE_FOOD_PLAN_1",
            uri: "https://campuscafe.online/wp-content/uploads/speiseplaene/MeinCampusCaf%C3%A9_Speiseplan_Pausenb%C3%BCffet_CampusCaf%C3%A9_Effner.pdf",
            static: true,
            name: "CampusCafé - Pausenbüffet",
            createdAt: ISO8601DateFormatter().date(from: "2023-09-22T16:20:00.000Z"),
            updatedAt: ISO8601DateFormatter().date(from: "2023-09-22T16:20:00.000Z"),
            v: 0
        ),
        Document(
            id: "650da32ac6f6aec2d78b6ba8",
            key: "DATA_INFORMATION_CAMPUS_CAFE_OVIEW_ALLERGENS",
            uri: "https://campuscafe.online/wp-content/uploads/2019/09/Allergen%C3%9Cbersicht_A4.pdf",
            static: true,
            name: "CampusCafé - Übersicht Allergene",
            createdAt: ISO8601DateFormatter().date(from: "2023-09-22T16:20:00.000Z"),
            updatedAt: ISO8601DateFormatter().date(from: "2023-09-22T16:20:00.000Z"),
            v: 0
        ),
        Document(
            id: "650f423eb453d34257929bc9",
            key: "DATA_INFORMATION_NOTICE_11",
            uri: "https://go.effner.app/systemwechsel-g9",
            static: true,
            name: "Information für die 11. Klassen",
            createdAt: ISO8601DateFormatter().date(from: "2023-09-23T12:00:00.000Z"),
            updatedAt: ISO8601DateFormatter().date(from: "2023-09-23T12:00:00.000Z"),
            v: 0
        ),
        Document(
            id: "691c31771a27f6001aa31626",
            key: "DATA_INFORMATION_836d38f5-52ce-4caa-a7f1-2310a2dfa1ca",
            uri: "https://effner.de/unterricht/gemeinsam-bruecken-bauen/",
            static: false,
            name: "Archiv: gemeinsam.Brücken.bauen",
            createdAt: ISO8601DateFormatter().date(from: "2025-11-18T08:42:31.223Z"),
            updatedAt: ISO8601DateFormatter().date(from: "2025-11-18T08:42:31.223Z"),
            v: 0
        ),
        Document(
            id: "691c31781a27f6001aa31628",
            key: "DATA_INFORMATION_e81b2fa3-6718-4c87-b407-d13212f617b0",
            uri: "https://effner.de/unterricht/begabtenfoerderung/",
            static: false,
            name: "Begabtenförderung",
            createdAt: ISO8601DateFormatter().date(from: "2025-11-18T08:42:32.785Z"),
            updatedAt: ISO8601DateFormatter().date(from: "2025-11-18T08:42:32.785Z"),
            v: 0
        )
    ]
    }
}
