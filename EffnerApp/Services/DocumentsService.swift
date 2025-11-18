//
//  DocumentsService.swift
//  EffnerApp
//
//  Created by Luis Bros on 18.11.25.
//
import Foundation

class DocumentsService : ObservableObject {
    @Published var error: NetworkError?
    
    private let networkManager : NetworkManager
    
    init(networkManager: NetworkManager = NetworkManager.shared) {
        self.networkManager = networkManager
    }
    
    func fetchDocuments() async -> Result<DocumentsResponse, NetworkError> {
        do {
            let documentsResponse: DocumentsResponse = try await networkManager.fetch(from: DocumentsEndpoint())
            
            guard !documentsResponse.isEmpty else {
                self.error = .serverError(statusCode: 500, msg: "No documents objects available.")
                return .failure(self.error!)
            }
            
            return .success(documentsResponse)
        } catch let networkError as NetworkError {
            self.error = networkError
            return .failure(self.error!)
        } catch(let error) {
            self.error = .unknownError(statusCode: 0, msg: error.localizedDescription)
            return .failure(self.error!)
        }
    }
    
}
