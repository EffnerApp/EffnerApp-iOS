//
//  SubstitutionsCache.swift
//  EffnerApp
//
//  Created by Luis Bros on 08.11.25.
//

import Foundation
import Combine
import OSLog

class SubstitutionsCache: BaseCache<SubstitutionResponse> {
    private static let logger = Log.substitutions
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
            Self.logger.debug("Cache refreshed with mock data.")
            return
        }
        
        let substitutionsService = SubstitutionsService()
        let result = await substitutionsService.fetchSubstitutions()
        
        switch result {
        case .success(let response):
            if response.plans.isEmpty == false, let _ = response.plans.first {
                saveSubstitutions(response)
                Self.logger.info("Cache refreshed successfully with \(response.plans.count) plan(s).")
            } else {
                Self.logger.warning("No substitution plans available.")
                await setError()
            }
        case .failure(let error):
            await setError()
            Self.logger.error("Failed to refresh cache: \(error.localizedDescription)")
        }
    }
}
