//
//  HolidaysCache.swift
//  EffnerApp
//
//  Created by Luis Bros on 07.12.25.
//
import Foundation
import Combine
import OSLog

class HolidaysCache: BaseCache<[Holiday]> {
    private static let logger = Log.holidays
    static let shared = HolidaysCache()
    
    // Convenience accessor für bessere Lesbarkeit
    var cachedHolidays: [Holiday]? {
        cachedResponse
    }
    
    // Überschreiben von hasError, um auch leere Daten als Error zu behandeln
    override var hasError: Bool {
        if case .error = loadState {
            return true
        }
        // Auch Error wenn Daten leer sind
        if case .loaded(let holidays) = loadState, holidays.isEmpty {
            return true
        }
        return false
    }
    
    // Convenience-Methode für bessere API
    public func saveHolidays(_ holidays: [Holiday]) {
        saveResponse(holidays)
    }
    
    // Implementation der Cache-Refresh-Logik
    override public func refreshCache() async {
        guard isUserAuthorized() else { return }
        
        await setLoading()
        
        // Mock-Daten für Test-User
        if shouldUseMockData() {
            saveHolidays(MockHolidays.mockHolidays)
            Self.logger.debug("Cache refreshed with mock data.")
            return
        }
        
        let holidaysService = HolidaysService()
        let result = await holidaysService.fetchHolidays()
        
        switch result {
        case .success(let holidays):
            saveHolidays(holidays)
            Self.logger.info("Exams Cache refreshed successfully.")
        case .failure(let error):
            let statusCode = extractStatusCode(from: error)
            await setError(statusCode: statusCode)
            Self.logger.error("Failed to refresh cache: \(error.localizedDescription)")
        }
    }
}
