//
//  EffnerAppTests.swift
//  EffnerAppTests
//
//  Created by Luis Bros on 29.06.25.
//

import Testing
@testable import EffnerApp

@Suite("Effner App Tests")
struct EffnerAppTests {
    
    // Dummy Login-Daten für Tests
    static let username = "193622"
    static let password = "JEG1952"
    static let dummyClass = "5A"
    
    // Diese Funktion wird vor allen Tests in dieser Suite ausgeführt
    init() async throws {
        // Erstelle einen Dummy-User für Tests
        let testUser = User(
            id: Self.username,
            password: Self.password,
            klass: Self.dummyClass,
            isAuthorized: true
        )
        
        // Setze den User in der UserSession
        await MainActor.run {
            UserSession.shared.user = testUser
        }
        
        print("✅ Test-Setup abgeschlossen: Dummy-User authentifiziert")
    }

    @Test func loginTest() async throws {
        // Überprüfe, dass der User authentifiziert ist
        let currentUser = await MainActor.run {
            UserSession.shared.user
        }
        
        #expect(currentUser != nil, "User sollte nach dem Setup vorhanden sein")
        #expect(currentUser?.id == Self.username, "Username sollte übereinstimmen")
        #expect(currentUser?.isAuthorized == true, "User sollte autorisiert sein")
    }
    
    @Test func timetableTest() async throws {
        let timetablesService = TimetablesService()
        let timetables = await timetablesService.fetchTimetable()
        
        print(timetables)
        
        
    }

}
