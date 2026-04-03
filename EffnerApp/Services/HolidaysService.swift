//
//  HolidaysService.swift
//  EffnerApp
//
//  Created by Luis Bros on 07.12.25.
//

import Foundation

class HolidaysService : ObservableObject {
    @Published var error: NetworkError?
    
    private let networkManager : NetworkManager
    
    init(networkManager: NetworkManager = NetworkManager.shared) {
        self.networkManager = networkManager
    }
    
    func fetchHolidays() async -> Result<[Holiday], NetworkError> {
        do {
            let holidays: [Holiday] = try await networkManager.fetch(from: HolidaysEndpoint())
            
            guard !holidays.isEmpty else {
                self.error = .serverError(statusCode: 500, msg: "No holiday objects available.")
                return .failure(self.error!)
            }
            
            // Sortiere die Holidays nach starts_on
            let sortedHolidays = holidays.sorted { $0.startsOn < $1.startsOn }
            
            return .success(sortedHolidays)
        } catch let networkError as NetworkError {
            self.error = networkError
            return .failure(self.error!)
        } catch(let error) {
            self.error = .unknownError(statusCode: 0, msg: error.localizedDescription)
            return .failure(self.error!)
        }
    }
    
}
