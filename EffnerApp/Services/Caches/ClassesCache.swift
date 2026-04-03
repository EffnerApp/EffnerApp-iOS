//
//  ClassesCache.swift
//  EffnerApp
//
//  Created by Luis Bros on 31.08.25.
//
import Foundation
import Combine
import OSLog


class ClassesCache: BaseCache<[String]> {
    private static let logger = Log.classes
    static let shared = ClassesCache()
    
    // Convenience accessor für bessere Lesbarkeit
    var cachedClasses: [String] {
        cachedResponse ?? []
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
    public func saveClasses(_ classes: [String]) {
        saveResponse(classes)
    }

    // Implementation der Cache-Refresh-Logik
    override public func refreshCache() async {
        await setLoading()
        
        let classesService = ClassesService()
        let result = await classesService.fetchClasses()
        
        switch result {
        case .success(let response):
            saveClasses(response)
            Self.logger.info("Cache refreshed successfully.")
        case .failure(let error):
            await setError()
            Self.logger.error("Failed to refresh cache: \(error.localizedDescription)")
        }
    }
}
