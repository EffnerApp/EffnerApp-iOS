//
//  DocumentsCache.swift
//  EffnerApp
//
//  Created by Luis Bros on 18.11.25.
//
import Foundation
import Combine
import OSLog

class DocumentsCache: BaseCache<DocumentsResponse> {
    private static let logger = Log.documents
    static let shared = DocumentsCache()
    
    // Convenience accessor für bessere Lesbarkeit
    var cachedDocumentsResponse: DocumentsResponse? {
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
    public func saveDocuments(_ documents: DocumentsResponse) {
        saveResponse(documents)
    }
    
    // Implementation der Cache-Refresh-Logik
    override public func refreshCache() async {
        guard isUserAuthorized() else { return }
        
        await setLoading()
        
        // Mock-Daten für Test-User
        if shouldUseMockData() {
            saveDocuments(DocumentsMock.mockDocuments())
            Self.logger.debug("Cache refreshed with mock data.")
            return
        }
        
        let documentsService = DocumentsService()
        let result = await documentsService.fetchDocuments()
        
        switch result {
        case .success(let response):
            saveDocuments(response)
            Self.logger.info("Docu Cache refreshed successfully.")
        case .failure(let error):
            let statusCode = extractStatusCode(from: error)
            await setError(statusCode: statusCode)
            Self.logger.error("Failed to refresh cache: \(error.localizedDescription)")
        }
    }
}
