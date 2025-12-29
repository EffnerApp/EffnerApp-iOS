//
//  ExamsCache.swift
//  EffnerApp
//
//  Created by Luis Bros on 31.08.25.
//
import Foundation
import Combine

class ExamsCache: BaseCache<ExamsResponse> {
    static let shared = ExamsCache()
    
    // Convenience accessor für bessere Lesbarkeit
    var cachedExamResponse: ExamsResponse? {
        cachedResponse
    }
    
    // Überschreiben von isEmpty, um leere Exams zu prüfen
    override var isEmpty: Bool {
        guard let response = cachedResponse else { return true }
        return response.exams.isEmpty
    }
    
    // Convenience-Methode für bessere API
    public func saveExams(_ examResponse: ExamsResponse) {
        saveResponse(examResponse)
    }
    
    // Implementation der Cache-Refresh-Logik
    override public func refreshCache() async {
        guard isUserAuthorized() else { return }
        
        await setLoading()
        
        // Mock-Daten für Test-User
        if shouldUseMockData() {
            saveExams(MockExam.mockExams)
            print("Exams cache refreshed with mock data.")
            return
        }
        
        let examsService = ExamsService()
        let result = await examsService.fetchExams()
        
        switch result {
        case .success(let response):
            if !response.exams.isEmpty {
                saveExams(response)
                print("Exams cache refreshed successfully.")
            } else {
                print("No exams available.")
                await setError()
            }
        case .failure(let error):
            await setError()
            print("Failed to refresh exams cache: \(error.localizedDescription)")
        }
    }
}
