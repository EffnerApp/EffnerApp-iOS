//
//  SubstitutionsService.swift
//  EffnerApp
//
//  Created by Luis Bros on 08.11.25.
//

import Foundation

class SubstitutionsService : ObservableObject {
    @Published var error: NetworkError?
    
    private let networkManager : NetworkManager
    
    init(networkManager: NetworkManager = NetworkManager.shared) {
        self.networkManager = networkManager
    }
    
    func fetchSubstitutions() async -> Result<SubstitutionResponse, NetworkError> {
        do {
            // SSB API returns [SubstitutionPlan] directly
            let plans: [SubstitutionPlan] = try await networkManager.fetch(from: SubstitutionsEndpoint())
            let response = SubstitutionResponse(plans: plans)
            
            return .success(response)
        } catch let networkError as NetworkError {
            self.error = networkError
            return .failure(networkError)
        } catch {
            let unknownError = NetworkError.unknownError(req: nil, statusCode: 0, msg: error.localizedDescription)
            self.error = unknownError
            return .failure(unknownError)
        }
    }
    
}
