//
//  TimetablesCache.swift
//  EffnerApp
//
//  Created by Luis Bros on 16.11.25.
//

import Foundation
import Combine

class TimetablesCache: BaseCache<TimetableResponse> {
    static let shared = TimetablesCache()
    
    // Convenience accessor für bessere Lesbarkeit
    var cachedTimetableResponse: TimetableResponse? {
        cachedResponse
    }
    
    // Überschreiben von hasError, um auch leere Daten als Error zu behandeln
    override var hasError: Bool {
        if case .error = loadState {
            return true
        }
        // Auch Error wenn Daten leer sind
        if case .loaded(let response) = loadState, response.data.isEmpty {
            return true
        }
        return false
    }
    
    // Convenience-Methode für bessere API
    public func saveTimetables(_ timetables: TimetableResponse) {
        saveResponse(timetables)
    }
    
    // Implementation der Cache-Refresh-Logik
    override public func refreshCache() async {
        guard isUserAuthorized() else { return }
        
        await setLoading()
        
        // Mock-Daten für Test-User
        if shouldUseMockData() {
            saveTimetables(MockTimetable.mockEmpty)
            print("Timetable cache refreshed with mock data.")
            return
        }
        
        let timetablesService = TimetablesService()
        let result = await timetablesService.fetchTimetable()
        
        switch result {
        case .success(let response):
            saveTimetables(response)
            print("Timetable cache refreshed successfully.")
        case .failure(let error):
            await setError()
            print("Failed to refresh Timetable cache: \(error.localizedDescription)")
        }
    }
}
