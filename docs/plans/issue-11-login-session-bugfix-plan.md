# Plan: Behebung von GitHub Issue #11 – Session-Lifecycle, Klassenvalidierung & Anmelde-Bugfixes

> **Leitprinzip der Umsetzung:**
> **Minimaler Code-Impact / Minimale Invasivität & Behavior-Driven Testing.** Es soll so wenig bestehender Code wie möglich geändert werden. Bestehende Architekturmuster, Interfaces, SwiftUI-Views, Preview-/Mock-Flows (`"test"`) und Namenskonventionen bleiben unverändert. Änderungen erfolgen chirurgisch präzise nur an den fehlerhaften Kontrollflüssen, Force-Unwraps und Validierungsgrenzen, ohne Nebeneffekte auf bestehende Userflows.
> **Der Code muss den Tests entsprechen – nicht andersherum:** Alle Soll-Flows (Login, Autorisierung, Offline-Resilienz, Selbstheilung, 401-Logout) werden über komplett serverlose End-to-End-Flow-Tests (mittels `URLProtocol`-Stubbing auf HTTP-Transportebene) gegen das gewünschte Verhalten verifiziert.

---

## 1. Kontext & Ausgangslage

Bei der Analyse der Produktions-Logs des SchoolService-Backends (`schoolservice-app`) sowie im Rahmen von [GitHub Issue #11](https://github.com/EffnerApp/EffnerApp-iOS/issues/11) wurden zusammenhängende Schwachstellen im Session-Lifecycle der iOS-App festgestellt:

* **62x `AUTH_USER_NOT_FOUND`:** Die App sendet wiederholt Anfragen mit Benutzer-UUIDs, die auf dem Server gelöscht wurden, weil bei Auth-Fehlern der lokale Speicher (Keychain & UserDefaults) nicht bereinigt wurde.
* **20x `AUTH_MALFORMED_USER_ID`:** Die App rief `GET /api/users/` mit leerem `X-User-Id: ""` Header auf, weil unvollständige Daten aus dem Keychain mit `?? ""` eingelesen wurden.
* **55x `USER_EMPTY_CLASSES`:** Benutzerprofile wurden mit leeren Klassenlisten geführt (`primaryClass == nil`), u. a. weil `updateUserKlasses(_:)` leere Arrays nicht abfing und `loadUserFromStorage()` nicht auf `!klasses.isEmpty` prüfte.
* **Invalide Endpunkt-Aufrufe:** Requests an `/api/timetables/class/`, `/api/exams/class/` und `/api/substitutions/class//upcoming` ohne gültigen Klassennamen.

---

## 2. Kernursachen & Zielzustand

| # | Datei(en) | Problem | Geplante minimale Anpassung |
|---|---|---|---|
| **1** | `EffnerApp/Models/User.swift` | `guard let klasses` schlägt bei leerem Array `[]` nicht fehl (`[] != nil`). Keychain-Werte werden unvollständig mit `?? ""` eingelesen. | In `loadUserFromStorage()` prüfen, dass `!klasses.isEmpty`, `username`/`password`/`ssbToken` nicht leer und `ssbId` eine gültige UUID ist. Ungültige Restdaten sofort über `Self.clearLocalStorage()` bereinigen. |
| **2** | `EffnerApp/Models/User.swift` | `updateUserKlasses(_:)` akzeptiert leere Arrays `[]`, speichert sie in `UserDefaults` und sendet sie an den Server (`USER_EMPTY_CLASSES`). Zudem werden `user!` Force-Unwraps genutzt. | In `updateUserKlasses` und `setPrimaryClass` mit `guard !validKlasses.isEmpty, var currentUser = user` absichern. |
| **3** | `EffnerApp/Models/User.swift` | Bei Fehlschlag von `authorize()` wird nur `self.user = nil` gesetzt; Keychain und UserDefaults bleiben erhalten. `logout()` verlässt sich auf `user?.clearCredentials()`. | Zentrale Methode `clearLocalStorage()` wiederverwenden. `logout(deleteRemoteUser: Bool = true)` sowie extrahierbare Methode `verifySession()` einführen: Bei 401/403/404 wird `await logout(deleteRemoteUser: false)` aufgerufen (verhindert unnötige `DELETE`-Requests & Endlosschleifen). Bei Offline-/Netzwerkfehlern bleibt die Offline-Session erhalten. |
| **4** | `EffnerApp/Services/Caches/BaseCache.swift` & Endpoints | Caches prüfen nur `isUserAuthorized()`, aber nicht `primaryClass`. Endpoints nutzen `user!`-Force-Unwraps, die bei asynchronem Logout crashen können. | `hasValidPrimaryClass()` in `BaseCache` ergänzen (inkl. Berücksichtigung von `shouldUseMockData()` für `"test"`). In `ExamsEndpoint`, `TimetablesEndpoint`, `SubstitutionsEndpoint`, `UpdateKlassesEndpoint` sicheres Optional-Chaining `user?` statt `user!` verwenden. |
| **5** | `EffnerApp/Networking/NetworkingManager.swift` | Keine automatische Abmeldung bei 401/403 im laufenden App-Betrieb. `init(session:)` ist `private`, was isolierte HTTP-Tests erschwert. | `init(session:)` auf `internal` öffnen. Bei 401/403 – **nur** wenn der Request Token-Auth (`X-User-Id` Header) nutzt – `Notification.Name.userUnauthorized` senden. `UserSession` fängt dies ab und führt `logout(deleteRemoteUser: false)` aus. |
| **6** | `EffnerApp/Views/LoginView.swift` & `AuthService.swift` | Fehlertexte bei fehlgeschlagener Anmeldung sind technische Strings (`Client error occurred. Status code: 401 Message: None`). | Verständliche deutsche Fehlermeldungen anzeigen und bei erfolgreichem `register()` vor dem Speichern etwaige Altlasten via `UserSession.clearLocalStorage()` bereinigen. |

---

## 3. Detaillierter Umsetzungsplan (Schritt für Schritt)

### Schritt 1: Strikte Storage-Validierung, Self-Healing & Schutz vor leeren Klassen (`User.swift`)

* **Datei:** `EffnerApp/Models/User.swift`
* **Logik in `loadUserFromStorage()`:**
  ```swift
  guard let cred, !cred.key.isEmpty, !cred.value.isEmpty,
        let ssbCred, !ssbCred.key.isEmpty, !ssbCred.value.isEmpty,
        UUID(uuidString: ssbCred.key) != nil,
        let klasses = klasses, !klasses.isEmpty else {
      Self.logger.info("Incomplete or corrupted credentials in storage. Purging.")
      Self.clearLocalStorage()
      return nil
  }
  ```
* **Logik in `setPrimaryClass(_:)` und `updateUserKlasses(_:)`:**
  * Verhindert das Entstehen von `USER_EMPTY_CLASSES` an der Wurzel und ersetzt gefährliche `user!`-Force-Unwraps:
  ```swift
  @MainActor
  func setPrimaryClass(_ className: String) {
      guard className.isValidClassName, var currentUser = user else { return }
      var updatedKlasses = currentUser.klasses.filter { $0 != className }
      updatedKlasses.insert(className, at: 0)
      
      if currentUser.klasses != updatedKlasses {
          currentUser.klasses = updatedKlasses
          currentUser.saveKlasses()
          self.user = currentUser
      }
      objectWillChange.send()
  }

  func updateUserKlasses(_ newKlasses: [String]) {
      let validKlasses = newKlasses.filter { $0.isValidClassName }
      guard !validKlasses.isEmpty, var currentUser = user else { return }
      let oldKlasses = currentUser.klasses
      
      if oldKlasses != validKlasses {
          currentUser.klasses = validKlasses
          currentUser.saveKlasses()
          self.user = currentUser
          
          Task {
              if await NotificationService.shared.isEnabled {
                  _ = await NotificationService.shared.updateKlasses(klasses: validKlasses)
              }
          }
      }
  }
  ```

---

### Schritt 2: Garantierter Session-Reset & Verifizierbarer Startup-Check (`User.swift`)

* **Datei:** `EffnerApp/Models/User.swift`
* **Zentrale Speicherbereinigung (`clearLocalStorage()`):**
  * Funktioniert unabhängig davon, ob `self.user` bereits `nil` ist, und wird von `user?.clearCredentials()` / `logout()` wiederverwendet:
  ```swift
  static func clearLocalStorage(additionalKlasses: [String] = []) {
      let storedKlasses = UserDefaults.standard.stringArray(forKey: "userKlasses") ?? []
      for klass in Set(storedKlasses + additionalKlasses) {
          UserDefaults.standard.removeObject(forKey: "subjectSelections_\(klass)")
          UserDefaults.standard.removeObject(forKey: "cachedTimetable_\(klass)")
      }
      KeyChainUtil.deleteFromKeyChain(serviceName: Constants.bundleIdentifier)
      KeyChainUtil.deleteFromKeyChain(serviceName: Constants.bundleIdentifier + ".ssb")
      UserDefaults.standard.removeObject(forKey: "userKlasses")
      UserDefaults.standard.removeObject(forKey: "userDeviceToken")
      UserDefaults.standard.set(false, forKey: "notificationsEnabled")
  }
  ```
* **Erweiterung von `logout(deleteRemoteUser: Bool = true)`:**
  * Beim manuellen Abmelden in `SettingsView` (`await session.logout()`) bleibt das Verhalten identisch (`deleteRemoteUser == true` ruft `NotificationService.shared.deleteUser()` auf).
  * Bei automatischer Abmeldung durch 401/403/404 wird `await logout(deleteRemoteUser: false)` aufgerufen:
    * Kein unnötiger `DELETE /users/{id}`-Request für einen bereits ungültigen/gelöschten User.
    * Keine Gefahr einer 401-Endlosschleife.
    * Bereinigt garantiert Keychain & UserDefaults via `Self.clearLocalStorage(additionalKlasses: user?.klasses ?? [])`.
* **Kapselung des Startup-Checks in `@MainActor func verifyStoredSession(authService: AuthService = AuthService()) async`:**
  * `UserSession.init()` ruft diese Methode auf. Gleichzeitig kann der komplette App-Start-Lifecycle in Unit-Tests deterministisch mit `await UserSession.shared.verifyStoredSession(authService: ...)` durchlaufen und getestet werden:
  ```swift
  @MainActor
  func verifyStoredSession(authService: AuthService = AuthService()) async {
      isCheckingAuthorization = true
      user = loadUserFromStorage()
      
      guard let currentUser = user else {
          Self.logger.info("No valid user found in storage.")
          isCheckingAuthorization = false
          objectWillChange.send()
          return
      }
      
      let isAuthorized = await authService.authorize(user: currentUser)
      switch isAuthorized {
      case .success(let response):
          Self.logger.info("User is authorized.")
          self.user?.isAuthorized = true
          self.user?.deviceToken = response.deviceToken
          ...
      case .failure(let error):
          Self.logger.error("Authorization failed with error: \(error)")
          if case .clientError(_, let statusCode, _) = error, [401, 403, 404].contains(statusCode) {
              await logout(deleteRemoteUser: false)
          } else {
              // Offline / temporärer Serverfehler (Timeout, 5xx):
              // Nutzer NICHT abmelden und self.user NICHT auf nil setzen, damit Offline-Stundenplan funktioniert!
              Self.logger.warning("Network issue during auth check. Retaining offline session.")
          }
      }
      self.isCheckingAuthorization = false
      objectWillChange.send()
  }
  ```

---

### Schritt 3: Caches & Endpoints vor ungültiger Klasse und Force-Unwrap-Crashes schützen

* **Dateien:**
  * `EffnerApp/Services/Caches/BaseCache.swift`
  * `EffnerApp/Services/Caches/ExamsCache.swift`
  * `EffnerApp/Services/Caches/TimetablesCache.swift`
  * `EffnerApp/Services/Caches/SubstitutionsCache.swift`
  * `EffnerApp/Repositories/ExamsEndpoint.swift`
  * `EffnerApp/Repositories/TimetablesEndpoint.swift`
  * `EffnerApp/Repositories/SubstitutionsEndpoint.swift`
  * `EffnerApp/Repositories/SSB/UpdateKlassesEndpoint.swift`
* **Logik in `BaseCache.swift`:**
  ```swift
  /// Prüft, ob eine gültige primäre Klasse (oder der Mock-Modus) vorliegt
  func hasValidPrimaryClass() -> Bool {
      if shouldUseMockData() { return true }
      guard let primaryClass = UserSession.shared.user?.primaryClass else { return false }
      return primaryClass.isValidClassName
  }
  ```
* **Logik in `ExamsCache`, `TimetablesCache`, `SubstitutionsCache`:**
  ```swift
  guard isUserAuthorized(), hasValidPrimaryClass() else { return }
  ```
* **Crash-Sicherheit in Endpoints:**
  * In `ExamsEndpoint`, `TimetablesEndpoint`, `SubstitutionsEndpoint` und `UpdateKlassesEndpoint` wird `UserSession.shared.user!` durch `UserSession.shared.user?` ersetzt (analog zu `HolidaysEndpoint` und `DeleteUserEndpoint`), damit bei einem zeitgleichen Logout während eines laufenden Tasks niemals ein Force-Unwrap-Crash auftreten kann.

---

### Schritt 4: Nebeneffektfreier 401/403-Handler im laufenden Betrieb (`NetworkingManager.swift`)

* **Dateien:**
  * `EffnerApp/Networking/NetworkingManager.swift`
  * `EffnerApp/Models/User.swift`
* **Logik in `NetworkingManager.swift`:**
  * `init(session: URLSession = .shared)` von `private` auf `internal` ändern (1 Wort Änderung), damit Tests einen `NetworkManager` mit eigener `MockURLProtocol`-Session injizieren können, ohne eine einzige Zeile Produktionslogik zu verbiegen.
  * Notification definieren:
    ```swift
    extension Notification.Name {
        static let userUnauthorized = Notification.Name("userUnauthorized")
    }
    ```
  * In `validateResponse(_:_:)` das Event **ausschließlich** für bestehende Token-Sessions (`X-User-Id` Header vorhanden) auslösen:
    ```swift
    case 400...499:
        if (response.statusCode == 401 || response.statusCode == 403),
           request.value(forHTTPHeaderField: "X-User-Id") != nil {
            NotificationCenter.default.post(name: .userUnauthorized, object: nil)
        }
        throw NetworkError.clientError(req: request, statusCode: response.statusCode)
    ```
* **Logik in `UserSession` (`User.swift`):**
  * Beobachtet `.userUnauthorized` und ruft auf dem `@MainActor`, sofern `self.user != nil`, `await logout(deleteRemoteUser: false)` auf.

---

### Schritt 5: Verständliche Fehlermeldungen beim Login (`LoginView.swift` & `AuthService.swift`)

* **Dateien:**
  * `EffnerApp/Views/LoginView.swift`
  * `EffnerApp/Services/AuthService.swift`
* **Logik in `AuthService.register()`:**
  * Nach erfolgreichem `CreateUserEndpoint`-Call (unmittelbar vor dem Speichern des neuen Users) wird `UserSession.clearLocalStorage()` aufgerufen, um eventuelle Restdaten früherer Sessions sauber zu entfernen, ohne bei einem fehlgeschlagenen Login-Versuch bestehenden State anzugreifen.
* **Logik in `LoginView.swift`:**
  * Mapping von `NetworkError` auf benutzerfreundliche deutsche Meldungen (z. B. als `var userFacingLoginMessage: String` auf `NetworkError` oder direkt für den Login):
    * `401` / `403`: `"Account ID oder Passwort ist nicht korrekt."`
    * `429`: `"Zu viele Anfragen. Bitte warte einen Moment und versuche es erneut."`
    * `unknownError(statusCode: 0)` (Offline/Timeout): `"Keine Verbindung zum Server möglich. Bitte überprüfe deine Internetverbindung."`
    * `serverError` (`500...599`): `"Der Server ist momentan nicht erreichbar. Bitte versuche es später erneut."`

---

## 4. Test-Architektur & Verhaltensgetriebene Tests (Ohne Server-Verbindung!)

### Grundprinzip unserer Tests:
> **Wir testen das gewünschte Systemverhalten an den echten Außengrenzen (HTTP-Wire-Level + echter Keychain + echte UserDefaults), nicht interne Implementierungsdetails!**
> Anstatt Services durch Fake-Klassen zu ersetzen, klinken wir uns über Apples natives **`URLProtocol` (`MockURLProtocol`)** auf unterster `URLSession`-Ebene ein. Dadurch durchläuft jeder Test den **kompletten echten Code-Pfad**:
> `UserSession` / `Login` / `Cache` $\rightarrow$ `Service` $\rightarrow$ `Endpoint.urlRequest()` (echte URL-Pfade & Auth-Header!) $\rightarrow$ `NetworkManager` $\rightarrow$ `MockURLProtocol` (kein Internet nötig!).

### Warum dieser Ansatz?
1. **100 % Offline & Deterministisch:** Kein einziger Test benötigt eine Verbindung zum `schoolservice-app`-Server (auch der bestehende `timetableTest` in `EffnerAppTests.swift`, der aktuell noch echte Netzwerkaufrufe macht, wird dadurch abgelöst bzw. abgesichert).
2. **Prüft echte HTTP-Requests:** Unser `MockURLProtocol` inspiziert den echten `URLRequest`, den die App erzeugt hat:
   * Ist `X-User-Id` eine echte UUID und niemals `""`?
   * Ist `Authorization: Basic ...` beim Login korrekt gesetzt?
   * Wurde jemals ein Request an `/exams/class/` oder `/timetables/class/` mit leerem Klassennamen gestellt? (Falls ja $\rightarrow$ Test schlägt sofort fehl!).
3. **Der Code muss den Tests folgen:** Die Tests formulieren als Spezifikation exakt die 7 fachlichen User-Flows aus Issue #11.

---

### Konkrete Test-Spezifikation (`EffnerAppTests/SessionFlowTests.swift`)

Wir erstellen eine dedizierte, seriell ausgeführte Swift-Testing-Suite (`@Suite("Session & Login Lifecycle Flows", .serialized)`), die vor und nach jedem Test den Zustand sauber isoliert:

#### Test 1: Kompletter Login-Flow (Happy Path) & Persistenz
* **Szenario:** Ein nicht angemeldeter Nutzer meldet sich mit gültiger Account-ID, Passwort und Klasse `"10A"` über `AuthService(networkManager: mockNM).register(...)` an.
* **Erwartetes Verhalten (Assertions):**
  1. Es geht exakt 1 `POST /users` Request mit `Authorization: Basic ...` und Body `{"classes":["10A"]}` über die Leitung.
  2. `UserSession.shared.user` ist gesetzt, `isAuthorized == true`, `primaryClass == "10A"`, `ssbId` ist die vom Server vergebene UUID.
  3. Im Keychain (`.bundleIdentifier` und `.bundleIdentifier + ".ssb"`) sowie in `UserDefaults` (`"userKlasses"`) sind die Daten vollständig gespeichert.
  4. Wird die App neu gestartet (`loadUserFromStorage()`), wird exakt dieser User wiederhergestellt.

#### Test 2: Fehlgeschlagener Login (401 Falsches Passwort / Ungültige Klasse)
* **Szenario A:** Server antwortet auf `POST /users` mit HTTP `401`.
* **Szenario B:** Nutzer versucht Login mit ungültiger Klasse `""` oder `"invalid"`.
* **Erwartetes Verhalten (Assertions):**
  1. Bei ungültiger Klasse geht **gar kein** Netzwerk-Request raus.
  2. Bei HTTP `401` bleibt `UserSession.shared.user == nil`.
  3. Es wird **kein** `.userUnauthorized`-Logout-Loop und **kein** `DELETE /users/` Request ausgelöst!
  4. Die benutzerfreundliche Fehlermeldung lautet `"Account ID oder Passwort ist nicht korrekt."` (statt `"Client error occurred. Status code: 401 Message: None"`).

#### Test 3: Selbstheilung bei korruptem Storage beim App-Start (Verhindert `AUTH_MALFORMED_USER_ID` & `USER_EMPTY_CLASSES`)
* **Szenario:** Im Storage liegen korrupte Daten aus älteren App-Versionen (Parametrisierter Test über alle kaputten Zustände):
  * Fall A: `ssbId` ist leer `""` oder keine gültige UUID (`"not-a-uuid"`).
  * Fall B: `userKlasses` ist ein leeres Array `[]` oder enthält nur ungültige Strings `["", "abc"]`.
  * Fall C: `username` oder `password` im Keychain fehlen.
* **Erwartetes Verhalten (Assertions):**
  1. Beim Start (`verifyStoredSession()`) wird `user == nil` gesetzt (`LoginView` wird angezeigt).
  2. **Kein einziger HTTP-Request** (`GET /users/`) wird an das Backend gesendet!
  3. Keychain und `UserDefaults` (`"userKlasses"`, `"userDeviceToken"`) sind nach dem Aufruf komplett bereinigt (Self-Healing).

#### Test 4: App-Start mit serverseitig gelöschtem Konto (401 / 403 / 404 bei `authorize()`) – Behebt `AUTH_USER_NOT_FOUND`
* **Szenario:** Gültige Session liegt im Keychain/UserDefaults. Beim App-Start (`verifyStoredSession()`) antwortet `GET /users/{uuid}` mit HTTP `401`, `403` oder `404` (Konto auf Server gelöscht).
* **Erwartetes Verhalten (Assertions):**
  1. `UserSession.shared.user` ist danach `nil`.
  2. Keychain und `UserDefaults` (inkl. gecachtem Stundenplan & Fächerauswahl) sind **vollständig gelöscht**.
  3. Es wurde **kein** `DELETE /users/{uuid}` Request gesendet.
  4. Ein erneuter App-Start (`loadUserFromStorage()`) liefert sofort `nil` und versucht **nicht** erneut, den gelöschten User beim Server abzufragen!

#### Test 5: App-Start im Offline-Modus / bei Server-Störung (Timeout / HTTP 500)
* **Szenario:** Angemeldeter Nutzer mit gespeichertem Stundenplan für `"10A"` startet die App im Flugmodus (`URLError(.notConnectedToInternet)`) oder bei Server-Ausfall (HTTP `502`/`503`).
* **Erwartetes Verhalten (Assertions):**
  1. `UserSession.shared.user` bleibt erhalten (`!= nil`) und `isAuthorized == true`!
  2. Keychain und `UserDefaults` werden **nicht** gelöscht.
  3. Der lokal gespeicherte Stundenplan (`user?.loadTimetable()`) ist weiterhin abrufbar.

#### Test 6: Laufender Betrieb – 401 bei Cache-Request löst sauberen Auto-Logout aus (ohne Endlosschleife)
* **Szenario:** Nutzer ist eingeloggt. Während der App-Nutzung lädt z. B. `ExamsService` oder `TimetablesService` Daten nach und der Server antwortet mit HTTP `401` (Session abgelaufen / User gelöscht).
* **Erwartetes Verhalten (Assertions):**
  1. `NetworkManager` erkennt den `401` auf dem Token-authentifizierten Request (`X-User-Id` vorhanden) und feuert `.userUnauthorized`.
  2. `UserSession` setzt `user = nil` und löscht Keychain sowie `UserDefaults` restlos.
  3. Es wird **kein** `DELETE /users/` Request nachgeschoben (0 weitere Requests!).
  4. Selbst wenn 4 Caches gleichzeitig `401` erhalten, läuft der Logout sauber und ohne Crash durch.

#### Test 7: Manueller Logout durch den Nutzer (`SettingsView`-Flow)
* **Szenario:** Eingeloggter Nutzer tippt aktiv auf "Abmelden" (`await UserSession.shared.logout()`).
* **Erwartetes Verhalten (Assertions):**
  1. Es wird `DELETE /users/{uuid}` an das Backend gesendet.
  2. `UserSession.shared.user` ist `nil`.
  3. Keychain, `UserDefaults` (`userKlasses`, `userDeviceToken`, `notificationsEnabled`, `cachedTimetable_...`, `subjectSelections_...`) und `TimetablesCache` sind komplett geleert.

#### Test 8: Schutz vor leeren Klassen im Betrieb & in Caches (Verhindert `/api/timetables/class/` & `USER_EMPTY_CLASSES`)
* **Szenario:**
  * Fall A: `updateUserKlasses([])` oder `updateUserKlasses(["ungueltig"])` wird aufgerufen.
  * Fall B: `ExamsCache.refreshCache()`, `TimetablesCache.refreshCache()` und `SubstitutionsCache.refreshCache()` werden aufgerufen, während `user?.klasses` leer ist.
* **Erwartetes Verhalten (Assertions):**
  1. `updateUserKlasses([])` verwirft das leere Update; die vorherige gültige Klasse `"10A"` bleibt erhalten und es geht kein `PUT /users/{id}/classes` mit `[]` raus.
  2. Die Caches brechen beim Guard `hasValidPrimaryClass()` sofort ab; es werden **0 HTTP-Requests** an `/exams/class/`, `/timetables/class/` oder `/substitutions/class//upcoming` abgesetzt.
  3. Für den Mock-User (`primaryClass == "test"`) liefern die Caches weiterhin wie gewohnt die Mock-Daten.
