//
//  ConfigCache.swift
//  EffnerApp
//
//  Created by Luis Bros on 18.11.25.
//

import Foundation
import Combine

class ConfigCache: BaseCache<String> {
    static let shared = ConfigCache()
    
    // Convenience accessor für bessere Lesbarkeit
    var cachedConfigResponse: String? {
        cachedResponse
    }
    
    // Überschreiben von hasError, um auch leere Daten als Error zu behandeln
    override var hasError: Bool {
        if case .error = loadState {
            return true
        }
        // Auch Error wenn Daten leer sind
        if case .loaded(let response) = loadState, response.isEmpty {
            return true
        }
        return false
    }
    
    // Convenience-Methode für bessere API
    public func saveConfig(_ config: String) {
        saveResponse(config)
    }
    
    // Implementation der Cache-Refresh-Logik
    override public func refreshCache() async {
        guard isUserAuthorized() else { return }
        
        await setLoading()
        
        // Mock-Daten für Test-User
        if shouldUseMockData() {
            saveConfig("yee")
            print("Config cache refreshed with mock data.")
            return
        }
        
        let configService = ConfigService()
        let result = await configService.fetchConfig()
        
        switch result {
        case .success(let response):
            saveConfig(response)
            print("Config cache refreshed successfully.")
        case .failure(let error):
            await setError()
            print("Failed to refresh Config cache: \(error.localizedDescription)")
        }
    }
}
