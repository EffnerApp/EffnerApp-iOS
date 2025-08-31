//
//  ExamsService.swift
//  EffnerApp
//
//  Created by Luis Bros on 12.08.25.
//
import Foundation

class ExamsService : ObservableObject {
    @Published var error: NetworkError?
    
    private let networkManager : NetworkManager
    
    init(networkManager: NetworkManager = NetworkManager.shared) {
        self.networkManager = networkManager
    }
    
    func fetchExams() async -> Result<ExamsResponse, NetworkError> {
        do {
            let examsResponse: ExamsResponse = try await networkManager.fetch(from: ExamsEndpoint())
            
            guard !examsResponse.exams.isEmpty else {
                self.error = .serverError(statusCode: 500, msg: "No exams available for this class.")
                return .failure(self.error!)
            }
            
            return .success(examsResponse)
        } catch let networkError as NetworkError {
            self.error = networkError
            return .failure(self.error!)
        } catch(let error) {
            self.error = .unknownError(statusCode: 0, msg: error.localizedDescription)
            return .failure(self.error!)
        }
    }
}

