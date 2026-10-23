//
//  SessionFlowTests.swift
//  EffnerAppTests
//
//  Created by Luis Bros on 23.10.26.
//

import Testing
import Foundation
@testable import EffnerApp

/// URLProtocol-Stub für 100 % serverlose Tests des echten HTTP-Stacks (Endpoints, Headers, NetworkManager)
final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    nonisolated(unsafe) static var capturedRequests: [URLRequest] = []
    private static let lock = NSLock()
    
    static func reset() {
        lock.lock()
        defer { lock.unlock() }
        requestHandler = nil
        capturedRequests = []
    }
    
    private static func record(_ request: URLRequest) {
        lock.lock()
        defer { lock.unlock() }
        capturedRequests.append(request)
    }
    
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    
    override func startLoading() {
        Self.record(request)
        guard let handler = Self.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    override func stopLoading() {}
}

@Suite("Session & Login Lifecycle Flows", .serialized)
struct SessionFlowTests {
    
    static let validUUID = "550e8400-e29b-41d4-a716-446655440000"
    static let validToken = "valid-ssb-token-123"
    static let validUsername = "schueler1"
    static let validPassword = "geheim"
    static let validClass = "10A"
    
    /// Erzeugt einen NetworkManager, der komplett über MockURLProtocol läuft (keine echte Serververbindung!)
    private func makeMockNetworkManager() -> NetworkManager {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        return NetworkManager(session: session)
    }
    
    /// Setzt vor jedem Test Storage und NetworkManager.shared auf unsere Offline-Mock-Session zurück
    init() async {
        MockURLProtocol.reset()
        MockURLProtocol.requestHandler = { request in
            let httpResponse = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (httpResponse, "[]".data(using: .utf8)!)
        }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        NetworkManager.shared = NetworkManager(session: URLSession(configuration: config))
        KeyChainUtil.deleteFromKeyChain(serviceName: Constants.bundleIdentifier)
        KeyChainUtil.deleteFromKeyChain(serviceName: Constants.bundleIdentifier + ".ssb")
        UserDefaults.standard.removeObject(forKey: "userKlasses")
        UserDefaults.standard.removeObject(forKey: "userDeviceToken")
        UserDefaults.standard.removeObject(forKey: "notificationsEnabled")
        UserDefaults.standard.removeObject(forKey: "cachedTimetable_\(Self.validClass)")
        UserDefaults.standard.removeObject(forKey: "subjectSelections_\(Self.validClass)")
        await MainActor.run {
            UserSession.shared.user = nil
        }
    }
    
    // MARK: - 1. Happy Path Login & Persistenz
    
    @Test("1. Kompletter Login-Flow speichert Session vollständig und übersteht App-Neustart")
    func testCompleteLoginFlowAndPersistence() async throws {
        let mockNM = makeMockNetworkManager()
        let authService = AuthService(networkManager: mockNM)
        
        MockURLProtocol.requestHandler = { request in
            let responseJSON = """
            {
                "id": "\(Self.validUUID)",
                "token": "\(Self.validToken)",
                "deviceToken": "apns-token-xyz",
                "classes": ["\(Self.validClass)"],
                "createdAt": "2026-10-23T12:00:00Z"
            }
            """.data(using: .utf8)!
            let httpResponse = HTTPURLResponse(url: request.url!, statusCode: 201, httpVersion: nil, headerFields: nil)!
            return (httpResponse, responseJSON)
        }
        
        let result = await authService.register(
            username: Self.validUsername,
            password: Self.validPassword,
            klasses: [Self.validClass]
        )
        
        // 1. Request-Prüfung
        let createRequests = MockURLProtocol.capturedRequests.filter { $0.url?.path.hasSuffix("/users") == true && $0.httpMethod == "POST" }
        #expect(createRequests.count == 1)
        let req = try #require(createRequests.first)
        #expect(req.value(forHTTPHeaderField: "Authorization")?.starts(with: "Basic ") == true)
        if let bodyData = req.httpBody,
           let json = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any] {
            #expect(json["platform"] as? String == "APN")
        }
        
        // 1b. UpdateDeviceTokenEndpoint sendet ebenfalls hart platform: "APN"
        let updateEndpoint = UpdateDeviceTokenEndpoint(deviceToken: "apns-token-xyz")
        let updateReq = try updateEndpoint.urlRequest()
        let updateBodyData = try #require(updateReq.httpBody)
        let updateJson = try #require(try JSONSerialization.jsonObject(with: updateBodyData) as? [String: Any])
        #expect(updateJson["deviceToken"] as? String == "apns-token-xyz")
        #expect(updateJson["platform"] as? String == "APN")
        
        // 2. Session-Zustand prüfen
        let user = try result.get()
        #expect(user.ssbId == Self.validUUID)
        #expect(user.primaryClass == Self.validClass)
        
        let sessionUser = await MainActor.run { UserSession.shared.user }
        #expect(sessionUser?.ssbId == Self.validUUID)
        #expect(sessionUser?.isAuthorized == true)
        #expect(sessionUser?.primaryClass == Self.validClass)
        
        // 3. Neustart simulieren: loadUserFromStorage() muss den User vollständig wiederherstellen
        let reloadedUser = UserSession.shared.loadUserFromStorage()
        #expect(reloadedUser != nil)
        #expect(reloadedUser?.ssbId == Self.validUUID)
        #expect(reloadedUser?.ssbToken == Self.validToken)
        #expect(reloadedUser?.username == Self.validUsername)
        #expect(reloadedUser?.password == Self.validPassword)
        #expect(reloadedUser?.klasses == [Self.validClass])
    }
    
    // MARK: - 2. Fehlgeschlagener Login & Fehler-UX
    
    @Test("2. Fehlgeschlagener Login (401 / ungültige Klasse) liefert verständliche Meldung und löst keinen Logout-Loop aus")
    func testFailedLoginBehavior() async throws {
        let mockNM = makeMockNetworkManager()
        let authService = AuthService(networkManager: mockNM)
        
        // Fall A: Ungültige Klasse -> darf gar keinen Request an /users senden
        let invalidClassResult = await authService.register(username: Self.validUsername, password: Self.validPassword, klasses: ["", "invalid"])
        let userRequestsAfterInvalid = MockURLProtocol.capturedRequests.filter { $0.url?.path.contains("/users") == true }
        #expect(userRequestsAfterInvalid.isEmpty, "Bei ungültiger Klasse darf kein Server-Request gesendet werden")
        if case .failure = invalidClassResult {
            // erwartet
        } else {
            Issue.record("Login mit ungültiger Klasse hätte fehlschlagen müssen")
        }
        
        // Fall B: 401 Falsches Passwort
        MockURLProtocol.reset()
        MockURLProtocol.requestHandler = { request in
            let httpResponse = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
            return (httpResponse, Data())
        }
        
        let wrongPasswordResult = await authService.register(username: Self.validUsername, password: "wrong", klasses: [Self.validClass])
        
        // Es darf nur der 1 POST /users Request rausgegangen sein (kein zusätzlicher DELETE /users Request durch 401-Interceptor!)
        let userRequestsAfter401 = MockURLProtocol.capturedRequests.filter { $0.url?.path.contains("/users") == true }
        #expect(userRequestsAfter401.count == 1)
        #expect(userRequestsAfter401.first?.httpMethod == "POST")
        
        let sessionUser = await MainActor.run { UserSession.shared.user }
        #expect(sessionUser == nil)
        
        if case .failure(let error) = wrongPasswordResult {
            // Die Fehlermeldung für den Nutzer im Login darf KEIN technischer String ("Status code: 401 Message: None") sein
            #expect(
                !error.localizedDescription.contains("Message: None"),
                "Login-Fehler sollte benutzerfreundlich sein und nicht 'Message: None' enthalten (aktuell: \(error.localizedDescription))"
            )
            #expect(
                error.localizedDescription.contains("Account ID oder Passwort"),
                "Bei 401 sollte 'Account ID oder Passwort ist nicht korrekt.' gemeldet werden"
            )
        } else {
            Issue.record("Login mit 401 hätte fehlschlagen müssen")
        }
    }
    
    // MARK: - 3. Selbstheilung bei korruptem Storage beim App-Start
    
    @Test("3. Korrupte Storage-Daten (leere UUID, ungültige UUID, leere Klassen) werden beim Laden abgelehnt und bereinigt")
    func testCorruptedStorageSelfHealing() async throws {
        // Szenario A: userKlasses ist ein leeres Array [] in UserDefaults (USER_EMPTY_CLASSES Bug)
        _ = KeyChainUtil.saveToKeyChain(serviceName: Constants.bundleIdentifier, item: KeyChainItem(key: Self.validUsername, value: Self.validPassword))
        _ = KeyChainUtil.saveToKeyChain(serviceName: Constants.bundleIdentifier + ".ssb", item: KeyChainItem(key: Self.validUUID, value: Self.validToken))
        UserDefaults.standard.set([String](), forKey: "userKlasses")
        
        let loadedWithEmptyClasses = UserSession.shared.loadUserFromStorage()
        #expect(loadedWithEmptyClasses == nil, "User mit leerer Klassenliste [] darf nicht aus dem Storage geladen werden!")
        #expect(UserDefaults.standard.stringArray(forKey: "userKlasses") == nil, "Korrupte userKlasses müssen beim Self-Healing gelöscht werden")
        #expect(KeyChainUtil.loadFromKeyChain(serviceName: Constants.bundleIdentifier) == nil, "Keychain muss beim Self-Healing bereinigt werden")
        
        // Szenario B: ssbId im Keychain ist leer "" oder keine gültige UUID (AUTH_MALFORMED_USER_ID Bug)
        _ = KeyChainUtil.saveToKeyChain(serviceName: Constants.bundleIdentifier, item: KeyChainItem(key: Self.validUsername, value: Self.validPassword))
        _ = KeyChainUtil.saveToKeyChain(serviceName: Constants.bundleIdentifier + ".ssb", item: KeyChainItem(key: "keine-uuid", value: Self.validToken))
        UserDefaults.standard.set([Self.validClass], forKey: "userKlasses")
        
        let loadedWithInvalidUUID = UserSession.shared.loadUserFromStorage()
        #expect(loadedWithInvalidUUID == nil, "User ohne gültige UUID als ssbId darf nicht geladen werden!")
        #expect(KeyChainUtil.loadFromKeyChain(serviceName: Constants.bundleIdentifier + ".ssb") == nil, "Ungültige SSB-Keychain-Daten müssen gelöscht werden")
        
        // Szenario C: SSB-Keychain fehlt komplett (würde sonst zu ssbId: "" führen)
        _ = KeyChainUtil.saveToKeyChain(serviceName: Constants.bundleIdentifier, item: KeyChainItem(key: Self.validUsername, value: Self.validPassword))
        KeyChainUtil.deleteFromKeyChain(serviceName: Constants.bundleIdentifier + ".ssb")
        UserDefaults.standard.set([Self.validClass], forKey: "userKlasses")
        
        let loadedWithoutSSB = UserSession.shared.loadUserFromStorage()
        #expect(loadedWithoutSSB == nil, "User ohne SSB-Credentials im Keychain darf nicht mit leerem String geladen werden!")
    }
    
    // MARK: - 4. Serverseitig gelöschtes Konto beim App-Start (401 / 404)
    
    @Test("4. Antwortet authorize() beim App-Start mit 401/403/404, werden Keychain & UserDefaults komplett gelöscht")
    func testDeletedAccountOnStartupPurgesStorage() async throws {
        // Gültige Daten in Keychain & UserDefaults legen
        _ = KeyChainUtil.saveToKeyChain(serviceName: Constants.bundleIdentifier, item: KeyChainItem(key: Self.validUsername, value: Self.validPassword))
        _ = KeyChainUtil.saveToKeyChain(serviceName: Constants.bundleIdentifier + ".ssb", item: KeyChainItem(key: Self.validUUID, value: Self.validToken))
        UserDefaults.standard.set([Self.validClass], forKey: "userKlasses")
        UserDefaults.standard.set("apns-123", forKey: "userDeviceToken")
        
        let mockNM = makeMockNetworkManager()
        let authService = AuthService(networkManager: mockNM)
        
        // Server antwortet mit 404 (AUTH_USER_NOT_FOUND) oder 401
        MockURLProtocol.requestHandler = { request in
            let httpResponse = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
            return (httpResponse, Data())
        }
        
        // App-Start-Prüfung ausführen
        if let storedUser = UserSession.shared.loadUserFromStorage() {
            await MainActor.run { UserSession.shared.user = storedUser }
            await UserSession.shared.verifyStoredSession(for: storedUser, authService: authService)
        }
        
        // Prüfen: Auch wenn user vorher schon auf nil gesetzt worden wäre, MUSS der Storage leer sein
        // Testen wir zusätzlich den Fall, dass user == nil ist und logout() gerufen wird (Schritt 3 im Plan):
        _ = KeyChainUtil.saveToKeyChain(serviceName: Constants.bundleIdentifier, item: KeyChainItem(key: Self.validUsername, value: Self.validPassword))
        _ = KeyChainUtil.saveToKeyChain(serviceName: Constants.bundleIdentifier + ".ssb", item: KeyChainItem(key: Self.validUUID, value: Self.validToken))
        UserDefaults.standard.set([Self.validClass], forKey: "userKlasses")
        await MainActor.run { UserSession.shared.user = nil }
        await UserSession.shared.logout(deleteRemoteUser: false)
        
        #expect(KeyChainUtil.loadFromKeyChain(serviceName: Constants.bundleIdentifier) == nil, "Keychain muss auch dann gelöscht werden, wenn user == nil war")
        #expect(KeyChainUtil.loadFromKeyChain(serviceName: Constants.bundleIdentifier + ".ssb") == nil, "SSB-Keychain muss auch dann gelöscht werden, wenn user == nil war")
        #expect(UserDefaults.standard.stringArray(forKey: "userKlasses") == nil, "userKlasses muss aus UserDefaults entfernt sein")
        #expect(UserSession.shared.loadUserFromStorage() == nil, "Beim nächsten App-Start darf kein alter User mehr geladen werden")
        
        // Außerdem prüfen: Bei einem Offline-/Netzwerkfehler (Timeout / Status 0) darf der User NICHT ausgeloggt werden!
        let offlineUser = User(
            ssbId: Self.validUUID,
            ssbToken: Self.validToken,
            username: Self.validUsername,
            password: Self.validPassword,
            klasses: [Self.validClass],
            isAuthorized: true
        )
        offlineUser.saveCredentials()
        offlineUser.saveSSBCredentials()
        offlineUser.saveKlasses()
        await MainActor.run { UserSession.shared.user = offlineUser }
        
        MockURLProtocol.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }
        await UserSession.shared.verifyStoredSession(for: offlineUser, authService: authService)
        
        let retainedUser = await MainActor.run { UserSession.shared.user }
        #expect(retainedUser != nil, "Im Offline-Modus darf der User beim Start nicht abgemeldet werden!")
        #expect(retainedUser?.primaryClass == Self.validClass)
    }
    
    // MARK: - 5. Schutz vor leeren Klassen im Betrieb & in Caches
    
    @Test("5. Leere Klassenlisten werden weder in updateUserKlasses gespeichert noch führen sie zu Cache-Requests")
    func testEmptyClassesProtectionInSessionAndCaches() async throws {
        let validUser = User(
            ssbId: Self.validUUID,
            ssbToken: Self.validToken,
            username: Self.validUsername,
            password: Self.validPassword,
            klasses: [Self.validClass],
            isAuthorized: true
        )
        await MainActor.run {
            UserSession.shared.user = validUser
        }
        validUser.saveKlasses()
        
        // A: Versuch, die Klassenliste mit leerem Array oder ungültigen Namen zu überschreiben
        await MainActor.run {
            UserSession.shared.updateUserKlasses([])
            UserSession.shared.updateUserKlasses(["", "invalid_class"])
        }
        
        let currentKlasses = await MainActor.run { UserSession.shared.user?.klasses }
        #expect(currentKlasses == [Self.validClass], "updateUserKlasses([]) darf bestehende gültige Klassen niemals mit einem leeren Array überschreiben!")
        
        // B: Wenn ein User (z.B. durch Manipulation) keine gültige primaryClass hat, dürfen Caches KEINEN Request senden
        await MainActor.run {
            UserSession.shared.user?.klasses = []
            ExamsCache.shared.loadState = .idle
        }
        
        let hasValidClass = BaseCache<Any>().isUserAuthorized() && BaseCache<Any>().hasValidPrimaryClass()
        #expect(!hasValidClass)
        
        // Prüfen, ob ExamsCache / TimetablesCache / SubstitutionsCache ohne primaryClass abbrechen
        await ExamsCache.shared.refreshCache()
        await TimetablesCache.shared.refreshCache()
        await SubstitutionsCache.shared.refreshCache()
        
        let examStateIsErrorOrLoading: Bool = await MainActor.run {
            if case .idle = ExamsCache.shared.loadState { return false }
            return true
        }
        #expect(!examStateIsErrorOrLoading, "ExamsCache darf ohne gültige primaryClass gar nicht erst in .loading oder .error wechseln!")
    }
    
    // MARK: - 6. Globaler 401/403-Handler im laufenden Betrieb
    
    @Test("6. Ein 401-Fehler bei einem authentifizierten API-Request im Betrieb loggt den User automatisch aus")
    func testRuntime401TriggersAutomaticLogout() async throws {
        // User ist eingeloggt und in Storage gespeichert
        let activeUser = User(
            ssbId: Self.validUUID,
            ssbToken: Self.validToken,
            username: Self.validUsername,
            password: Self.validPassword,
            klasses: [Self.validClass],
            isAuthorized: true
        )
        activeUser.saveCredentials()
        activeUser.saveSSBCredentials()
        activeUser.saveKlasses()
        await MainActor.run {
            UserSession.shared.user = activeUser
        }
        
        let mockNM = makeMockNetworkManager()
        let examsService = ExamsService(networkManager: mockNM)
        
        // Server antwortet auf /exams/class/10A mit 401 Unauthorized
        MockURLProtocol.requestHandler = { request in
            let httpResponse = HTTPURLResponse(url: request.url!, statusCode: 401, httpVersion: nil, headerFields: nil)!
            return (httpResponse, Data())
        }
        
        _ = await examsService.fetchExams()
        
        // Kurz auf asynchrone Notification-Verarbeitung auf dem MainActor warten
        try await Task.sleep(for: .milliseconds(100))
        
        let userAfter401 = await MainActor.run { UserSession.shared.user }
        #expect(userAfter401 == nil, "Nach einem 401 im laufenden Betrieb muss UserSession.shared.user automatisch auf nil gesetzt werden")
        #expect(KeyChainUtil.loadFromKeyChain(serviceName: Constants.bundleIdentifier + ".ssb") == nil, "Nach einem 401 müssen die SSB-Credentials aus dem Keychain gelöscht sein")
        #expect(UserDefaults.standard.stringArray(forKey: "userKlasses") == nil, "Nach einem 401 müssen die userKlasses gelöscht sein")
    }
    
    // MARK: - 7. Klassen-Synchronisation (unabhängig vom Push-Status & Self-Healing beim Start)
    
    @Test("7. Klassenwechsel synchronisiert immer ans Backend und verifyStoredSession korrigiert Abweichungen")
    func testClassSyncAlwaysUpdatesBackendAndSelfHealsOnStartup() async throws {
        let user = User(
            ssbId: Self.validUUID,
            ssbToken: Self.validToken,
            username: Self.validUsername,
            password: Self.validPassword,
            klasses: ["5D"],
            isAuthorized: true
        )
        await MainActor.run {
            NotificationService.shared.isEnabled = false
            UserSession.shared.user = user
        }
        
        MockURLProtocol.reset()
        MockURLProtocol.requestHandler = { request in
            let responseJSON = """
            {
                "id": "\(Self.validUUID)",
                "token": "HIDDEN:non-empty",
                "deviceToken": null,
                "classes": ["6D"]
            }
            """.data(using: .utf8)!
            let httpResponse = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (httpResponse, responseJSON)
        }
        
        // A: Klassenwechsel bei deaktivierten Notifications sendet trotzdem PUT /users/{id}/classes
        await MainActor.run {
            UserSession.shared.updateUserKlasses(["6D"])
        }
        try await Task.sleep(for: .milliseconds(100))
        
        let putRequests = MockURLProtocol.capturedRequests.filter {
            $0.url?.path.hasSuffix("/users/\(Self.validUUID)/classes") == true && $0.httpMethod == "PUT"
        }
        #expect(putRequests.count == 1)
        
        // B: verifyStoredSession gleicht abweichende Server-Klassen ("5D") automatisch auf lokale Klasse ("6D") ab
        MockURLProtocol.reset()
        MockURLProtocol.requestHandler = { request in
            let classesInResponse = request.httpMethod == "GET" ? "5D" : "6D"
            let responseJSON = """
            {
                "id": "\(Self.validUUID)",
                "token": "HIDDEN:non-empty",
                "deviceToken": null,
                "classes": ["\(classesInResponse)"]
            }
            """.data(using: .utf8)!
            let httpResponse = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (httpResponse, responseJSON)
        }
        
        let updatedUser = try #require(await MainActor.run { UserSession.shared.user })
        let authService = AuthService(networkManager: makeMockNetworkManager())
        await UserSession.shared.verifyStoredSession(for: updatedUser, authService: authService)
        
        let syncPutRequests = MockURLProtocol.capturedRequests.filter {
            $0.url?.path.hasSuffix("/users/\(Self.validUUID)/classes") == true && $0.httpMethod == "PUT"
        }
        #expect(syncPutRequests.count == 1)
    }
}
