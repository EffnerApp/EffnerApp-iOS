//
//  TimetablesService.swift
//  EffnerApp
//
//  Created by Luis Bros on 16.11.25.
//

import Foundation
import SwiftUI

class TimetablesService : ObservableObject {
    @Published var error: NetworkError?
    
    private let networkManager : NetworkManager
    
    init(networkManager: NetworkManager = NetworkManager.shared) {
        self.networkManager = networkManager
    }
    
    func fetchTimetable() async -> Result<TimetableResponse, NetworkError> {
        do {
            let timetableResponse: TimetableResponse = try await networkManager.fetch(from: TimetablesEndpoint())
            
            return .success(timetableResponse)
        } catch let networkError as NetworkError {
            self.error = networkError
            return .failure(self.error!)
        } catch(let error) {
            self.error = .unknownError(req: nil, statusCode: 0, msg: error.localizedDescription)
            return .failure(self.error!)
        }
    }
    
}
