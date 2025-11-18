//
//  DocumentsCache.swift
//  EffnerApp
//
//  Created by Luis Bros on 18.11.25.
//
import Foundation
import Combine

class DocumentsCache: BaseCache<DocumentsResponse> {
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
            print("Documents cache refreshed with mock data.")
            return
        }
        
        let documentsService = DocumentsService()
        let result = await documentsService.fetchDocuments()
        
        switch result {
        case .success(let response):
            saveDocuments(response)
            print("Documents cache refreshed successfully.")
        case .failure(let error):
            await setError()
            print("Failed to refresh Documents cache: \(error.localizedDescription)")
        }
    }
}
