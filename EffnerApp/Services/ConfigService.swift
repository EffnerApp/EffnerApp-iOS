//
//  ConfigService.swift
//  EffnerApp
//
//  Created by Luis Bros on 18.11.25.
//
import Foundation

class ConfigService : ObservableObject {
    @Published var error: NetworkError?
    
    private let networkManager : NetworkManager
    
    init(networkManager: NetworkManager = NetworkManager.shared) {
        self.networkManager = networkManager
    }
    
    func fetchConfig() async -> Result<String, NetworkError> {
        do {
            let configResponse: String = try await networkManager.fetch(from: ConfigEndpoint())
            
            guard !configResponse.isEmpty else {
                self.error = .serverError(statusCode: 500, msg: "No config objects available.")
                return .failure(self.error!)
            }
            
            return .success(configResponse)
        } catch let networkError as NetworkError {
            self.error = networkError
            return .failure(self.error!)
        } catch(let error) {
            self.error = .unknownError(statusCode: 0, msg: error.localizedDescription)
            return .failure(self.error!)
        }
    }
    
}
