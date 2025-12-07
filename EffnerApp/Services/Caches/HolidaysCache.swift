//
//  HolidaysCache.swift
//  EffnerApp
//
//  Created by Luis Bros on 07.12.25.
//
import Foundation
import Combine

class HolidaysCache: BaseCache<HolidayResponse> {
    static let shared = HolidaysCache()
    
    // Convenience accessor für bessere Lesbarkeit
    var cachedHolidaysResponse: HolidayResponse? {
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
    public func saveHolidays(_ holidays: HolidayResponse) {
        saveResponse(holidays)
    }
    
    // Implementation der Cache-Refresh-Logik
    override public func refreshCache() async {
        guard isUserAuthorized() else { return }
        
        await setLoading()
        
        // Mock-Daten für Test-User
        if shouldUseMockData() {
            saveHolidays(MockHolidays.mockHolidays)
            print("Holidays cache refreshed with mock data.")
            return
        }
        
        let holidaysService = HolidaysService()
        let result = await holidaysService.fetchHolidays()
        
        switch result {
        case .success(let response):
            saveHolidays(response)
            print("Holidays cache refreshed successfully.")
        case .failure(let error):
            await setError()
            print("Failed to refresh Holidays cache: \(error.localizedDescription)")
        }
    }
}
