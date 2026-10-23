//
//  FeedbackMailHelperTests.swift
//  EffnerAppTests
//
//  Created by Luis Bros.
//

import Testing
import Foundation
@testable import EffnerApp

@Suite("Feedback Mail Helper Tests")
struct FeedbackMailHelperTests {

    @Test("Feedback URL erzeugt gültige mailto URL mit allen Metadaten")
    func testFeedbackURLGeneration() throws {
        let testUser = User(
            ssbId: "user-test-id-12345",
            ssbToken: "token-abc",
            username: "max.mustermann",
            password: "password",
            klasses: ["10a", "11b"],
            isAuthorized: true
        )

        let url = FeedbackMailHelper.feedbackURL(user: testUser)
        
        #expect(url.scheme == "mailto")
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            Issue.record("URLComponents konnten nicht geparst werden")
            return
        }
        
        #expect(components.path == "support@effner.app")
        
        let subject = components.queryItems?.first(where: { $0.name == "subject" })?.value
        let body = components.queryItems?.first(where: { $0.name == "body" })?.value
        
        #expect(subject?.contains("EffnerApp Feedback") == true)
        
        let unwrappedBody = try #require(body)
        #expect(unwrappedBody.contains("User-ID: user-test-id-12345"))
        #expect(unwrappedBody.contains("Klassen: 10a, 11b"))
        #expect(unwrappedBody.contains("App-Version:"))
        #expect(unwrappedBody.contains("iOS-Version:"))
        #expect(unwrappedBody.contains("Gerät:"))
        #expect(unwrappedBody.contains("Status: Angemeldet"))
        #expect(unwrappedBody.contains("Uhrzeit:"))
    }

    @Test("Feedback URL ohne User setzt saubere Fallbacks")
    func testFeedbackURLFallbackWithoutUser() throws {
        let url = FeedbackMailHelper.feedbackURL(user: nil)
        
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            Issue.record("URLComponents konnten nicht geparst werden")
            return
        }
        
        let body = try #require(components.queryItems?.first(where: { $0.name == "body" })?.value)
        #expect(body.contains("User-ID: Nicht angemeldet"))
        #expect(body.contains("Klassen: Keine"))
        #expect(body.contains("Status: Nicht angemeldet"))
        #expect(body.contains("Uhrzeit:"))
    }
}
