//
//  TimetablesCache.swift
//  EffnerApp
//
//  Created by Luis Bros on 16.11.25.
//

import Foundation
import Combine
import OSLog

class TimetablesCache: BaseCache<TimetableResponse> {
    private static let logger = Log.timetable
    static let shared = TimetablesCache()
    
    override init() {
        super.init()
        loadInitialTimetable()
    }
    
    /// Lädt den Stundenplan sofort aus dem Storage, falls vorhanden
    public func loadInitialTimetable() {
        if let stored = UserSession.shared.user?.loadTimetable() {
            self.cachedResponse = stored
            self.loadState = .loaded(stored)
        }
    }
    
    /// Setzt den Cache zurück (z.B. beim Logout)
    public func clearCache() {
        self.cachedResponse = nil
        self.loadState = .idle
    }
    
    // Überschreiben von hasError, um auch leere Daten als Error zu behandeln
    override var hasError: Bool {
        if case .error = loadState {
            return true
        }
        // Auch Error wenn Daten leer sind
        if case .loaded(let response) = loadState, response.slots.isEmpty {
            return true
        }
        return false
    }
    
    // Convenience-Methode für bessere API
    public func saveTimetables(_ timetables: TimetableResponse) {
        UserSession.shared.user?.saveTimetable(timetables)
        saveResponse(timetables)
    }
    
    // Implementation der Cache-Refresh-Logik
    override public func refreshCache() async {
        guard isUserAuthorized() else { return }
        
        // Gespeicherten Stundenplan für die aktive Klasse laden, falls vorhanden
        if let stored = UserSession.shared.user?.loadTimetable() {
            await MainActor.run {
                self.cachedResponse = stored
                self.loadState = .loaded(stored)
            }
        } else {
            await MainActor.run {
                self.cachedResponse = nil
            }
            await setLoading()
        }
        
        // Mock-Daten für Test-User
        if shouldUseMockData() {
            saveTimetables(MockTimetable.mockTimetable)
            Self.logger.debug("Cache refreshed with mock data.")
            return
        }
        
        let timetablesService = TimetablesService()
        let result = await timetablesService.fetchTimetable()
        
        switch result {
        case .success(let response):
            saveTimetables(response)
            Self.logger.info("Timetable Cache refreshed successfully.")
        case .failure(let error):
            // Wenn bereits Daten aus dem Storage vorliegen, Status nicht auf Error setzen
            if cachedResponse == nil {
                let statusCode = extractStatusCode(from: error)
                await setError(statusCode: statusCode)
            }
            Self.logger.error("Failed to refresh cache: \(error.localizedDescription)")
        }
    }
}
