//
//  SubstitutionsCache.swift
//  EffnerApp
//
//  Created by Luis Bros on 08.11.25.
//

import Foundation
import Combine

class SubstitutionsCache: BaseCache<SubstitutionResponse> {
    static let shared = SubstitutionsCache()
    
    // Convenience accessor für bessere Lesbarkeit
    var cachedSubstitutionPlans: SubstitutionResponse? {
        cachedResponse
    }
    
    // Convenience-Methode für bessere API
    public func saveSubstitutions(_ plan: SubstitutionResponse) {
        saveResponse(plan)
    }
    
    // Implementation der Cache-Refresh-Logik
    override public func refreshCache() async {
        guard isUserAuthorized() else { return }
        
        await setLoading()
        
        // Mock-Daten für Test-User
        if shouldUseMockData() {
            saveSubstitutions(MockSubstitution.mockSubstitutionPlans)
            print("Substitutions cache refreshed with mock data.")
            return
        }
        
        let substitutionsService = SubstitutionsService()
        let result = await substitutionsService.fetchSubstitutions()
        
        switch result {
        case .success(let response):
            if response.plans.isEmpty == false, let _ = response.plans.first {
                saveSubstitutions(response)
                print("Substitutions cache refreshed successfully with \(response.plans.count) plan(s).")
            } else {
                print("No substitution plans available.")
                await setError()
            }
        case .failure(let error):
            await setError()
            print("Failed to refresh substitutions cache: \(error.localizedDescription)")
        }
    }
}
