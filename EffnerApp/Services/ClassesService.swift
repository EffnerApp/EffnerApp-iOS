//
//  ClassesService.swift
//  EffnerApp
//
//  Created by Luis Bros on 21.07.25.
//

import Foundation

class ClassesService : ObservableObject {
    @Published var error: NetworkError?
    
    private let networkManager : NetworkManager
    
    init(networkManager: NetworkManager = NetworkManager.shared) {
        self.networkManager = networkManager
    }
    
    func fetchClasses() async -> Result<[String], NetworkError> {
        do {
            let classesResponse: [String] = try await networkManager.fetch(from: ClassesEndpoint())
            
            guard !classesResponse.isEmpty else {
                self.error = .serverError(statusCode: 500, msg: "No classes available.")
                return .failure(self.error!)
            }
            
            return .success(classesResponse)
        } catch let networkError as NetworkError {
            self.error = networkError
            return .failure(self.error!)
        } catch(let error) {
            self.error = .unknownError(statusCode: 0, msg: error.localizedDescription)
            return .failure(self.error!)
        }
    }
        
}
