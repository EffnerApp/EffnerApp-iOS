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
        cachedResponse?.filter { $0.isValidClassName } ?? []
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
        let validClasses = classes.filter { $0.isValidClassName }
        saveResponse(validClasses)
    }

    // Implementation der Cache-Refresh-Logik
    override public func refreshCache() async {
        await setLoading()
        
        let classesService = ClassesService()
        let result = await classesService.fetchClasses()
        
        switch result {
        case .success(let response):
            saveClasses(response)
            Self.logger.info("Classes Cache refreshed successfully.")
        case .failure(let error):
            await setError()
            Self.logger.error("Failed to refresh cache: \(error.localizedDescription)")
        }
    }
}

extension String {
    /// Prüft, ob ein Klassenname gültig ist:
    /// 1-2 Ziffern gefolgt von 1-2 Großbuchstaben (z. B. 5A, 10B, 11CL, 12Q)
    /// oder Q-Stufen-Format (z. B. 12Q4, 13Q1).
    var isValidClassName: Bool {
        let trimmed = trimmingCharacters(in: .whitespaces)
        guard trimmed.count <= 4 else { return false }
        let pattern = #"^[0-9]{1,2}(?:[A-Z]{1,2}|[A-Z][0-9])$"#
        return trimmed.range(of: pattern, options: .regularExpression) != nil
    }
}
