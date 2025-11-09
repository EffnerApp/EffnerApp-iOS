//
//  SubstitutionsCache.swift
//  EffnerApp
//
//  Created by Luis Bros on 08.11.25.
//

import Foundation
import Combine

class SubstitutionsCache: ObservableObject {
    static let shared = SubstitutionsCache()
    
    @Published var cachedSubstitutionPlans: SubstitutionResponse? = nil {
        didSet {
            objectWillChange.send()
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        watchUserSession()
    }
    
    public func saveSubstitutions(_ plan: SubstitutionResponse) {
        DispatchQueue.main.async {
            self.cachedSubstitutionPlans = plan
        }
    }
    
    private func watchUserSession() {
        UserSession.shared.objectWillChange
            .sink { [weak self] _ in
                guard let self = self else { return }
                Task { @MainActor in
                    await self.refreshCache()
                }
            }
            .store(in: &cancellables)
    }
    
    public func refreshCache() async {
        if UserSession.shared.user == nil || !UserSession.shared.user!.isAuthorized {
            return
        }
        
        if UserSession.shared.user!.classA == "test" {
            self.saveSubstitutions(MockSubstitution.mockSubstitutionPlans)
            print("Substitutions cache refreshed with mock data.")
            return
        }
        
        let substitutionsService = SubstitutionsService()
        
        // Fetch from network
        let result = await substitutionsService.fetchSubstitutions()
        switch result {
            case .success(let response):
            if response.plans.isEmpty == false, let _ = response.plans.first {
                    self.saveSubstitutions(response)
                print("Substitutions cache refreshed successfully with \(response.plans.count) plan(s).")
                } else {
                    print("No substitution plans available.")
                }
            case .failure(let error):
                print("Failed to refresh substitutions cache: \(error.localizedDescription)")
        }
    }
}
