//
//  SubstitutionsService.swift
//  EffnerApp
//
//  Created by Luis Bros on 08.11.25.
//

import Foundation
import SwiftUI

class SubstitutionsService : ObservableObject {
    @Published var error: NetworkError?
    
    private let networkManager : NetworkManager
    
    init(networkManager: NetworkManager = NetworkManager.shared) {
        self.networkManager = networkManager
    }
    
    func fetchSubstitutions() async -> Result<SubstitutionResponse, NetworkError> {
        do {
            let subResponse: SubstitutionResponse = try await networkManager.fetch(from: SubstitutionsEndpoint())
            
            return .success(subResponse)
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
