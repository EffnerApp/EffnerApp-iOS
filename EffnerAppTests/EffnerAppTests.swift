//
//  EffnerAppTests.swift
//  EffnerAppTests
//
//  Created by Luis Bros on 29.06.25.
//

import Testing
import Foundation
@testable import EffnerApp

@Suite("Effner App Tests")
struct EffnerAppTests {
    
    // Dummy Login-Daten für Tests
    static let username = "username"
    static let password = "password"
    static let dummyClass = "5A"
    
    // Diese Funktion wird vor allen Tests in dieser Suite ausgeführt
    init() async throws {
        // Erstelle einen Dummy-User für Tests
        let testUser = User(
            ssbId: "test-ssb-id",
            ssbToken: "test-ssb-token",
            username: Self.username,
            password: Self.password,
            klasses: [Self.dummyClass],
            isAuthorized: true,
            deviceToken: nil
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
        #expect(currentUser?.username == Self.username, "Username sollte übereinstimmen")
        #expect(currentUser?.isAuthorized == true, "User sollte autorisiert sein")
    }
    
    @Test func timetableTest() async throws {
        let timetablesService = TimetablesService()
        let timetables = await timetablesService.fetchTimetable()
        
        print(timetables)
    }

    @Test func extraordinaryClassesTest() async throws {
        let serverClasses = ["5A", "6B", "7C"]
        let userKlasses = ["5A", "OldClass1", "OldClass2"]
        
        let serverSet = Set(serverClasses)
        let extraordinary = userKlasses.filter { !serverSet.contains($0) }
        
        #expect(extraordinary == ["OldClass1", "OldClass2"], "Klassen, die nicht vom Server geliefert werden, sollten als außergewöhnlich erkannt werden")
        
        // Simuliere Abwählen einer außergewöhnlichen Klasse
        var selectedClasses = userKlasses
        if let index = selectedClasses.firstIndex(of: "OldClass1"), selectedClasses.count > 1 {
            selectedClasses.remove(at: index)
        }
        
        #expect(!selectedClasses.contains("OldClass1"), "OldClass1 sollte abgewählt worden sein")
        #expect(selectedClasses.contains("OldClass2"), "OldClass2 sollte noch ausgewählt sein")
        #expect(selectedClasses.contains("5A"), "5A sollte noch ausgewählt sein")
        
        // Simuliere Speichern im User
        await MainActor.run {
            UserSession.shared.updateUserKlasses(selectedClasses)
        }
        
        let updatedUser = await MainActor.run {
            UserSession.shared.user
        }
        #expect(updatedUser?.klasses == ["5A", "OldClass2"], "User klasses sollten aktualisiert sein")
    }

    @Test func timetableStorageAndSelectionsTest() async throws {
        let testClass = "TestClass10"
        let mockTimetable = MockTimetable.mockTimetable
        
        // 1. User auf Testklasse setzen
        await MainActor.run {
            UserSession.shared.user?.klasses = [testClass]
        }
        
        // 2. Speichern im Storage über TimetablesCache (nutzt User.saveTimetable mit primaryClass)
        TimetablesCache.shared.saveTimetables(mockTimetable)
        
        // 3. Aus User Storage laden und prüfen
        let user = await MainActor.run {
            UserSession.shared.user!
        }
        let loadedTimetable = user.loadTimetable()
        #expect(loadedTimetable != nil, "Stundenplan sollte im User-Storage gespeichert worden sein")
        #expect(loadedTimetable?.slots.count == mockTimetable.slots.count, "Slots-Anzahl sollte übereinstimmen")
        
        // 4. Fächerauswahl (User Changes) speichern und laden
        let testSelections = ["0_0": "L", "0_1": "E"]
        user.saveSubjectSelections(testSelections)
        
        let loadedSelections = user.loadSubjectSelections()
        #expect(loadedSelections == testSelections, "Fächerauswahl des Nutzers sollte aus dem Storage geladen werden")
        
        // 5. Initiales Laden des Stundenplans beim App-Start testen
        await MainActor.run {
            TimetablesCache.shared.cachedResponse = nil
            TimetablesCache.shared.loadInitialTimetable()
        }
        
        let initialCached = await MainActor.run {
            TimetablesCache.shared.cachedResponse
        }
        #expect(initialCached != nil, "Stundenplan sollte beim Start sofort aus dem Storage geladen werden")
        #expect(initialCached?.slots.count == mockTimetable.slots.count, "Geladener Stundenplan sollte korrekt sein")
        
        // Cleanup
        UserDefaults.standard.removeObject(forKey: "cachedTimetable_\(testClass)")
        UserDefaults.standard.removeObject(forKey: "subjectSelections_\(testClass)")
    }

}
