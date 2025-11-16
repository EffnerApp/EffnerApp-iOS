//
//  TimetablesCache.swift
//  EffnerApp
//
//  Created by Luis Bros on 16.11.25.
//

import Foundation
import Combine

class TimetablesCache: ObservableObject {
    static let shared = TimetablesCache()
    @Published var cachedTimetableResponse: TimetableResponse? = nil {
        didSet {
            objectWillChange.send()
        }
    }
    
    @Published var hasError: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        watchUserSession()
    }
    
    
    public func saveTimetables(_ timetables: TimetableResponse) {
        DispatchQueue.main.async {
            self.cachedTimetableResponse = timetables
        }
    }
    
    public func watchUserSession() {
        UserSession.shared.objectWillChange
            .sink { [weak self] _ in
                guard let self = self else { return }
                Task {
                    await self.refreshCache()
                }
            }
            .store(in: &cancellables)
    }
    
    public func refreshCache() async {
        if(UserSession.shared.user == nil || !UserSession.shared.user!.isAuthorized) {
            return
        }
        
        // Set loading state
        await MainActor.run {
            hasError = false
            cachedTimetableResponse = nil
        }
        
        if(UserSession.shared.user!.klass == "test") {
            self.saveTimetables(MockTimetable.mockTimetable)
            print("Timetable cache refreshed with mock data.")
            return
        }
        let timetablesService = TimetablesService()
        
        // Fetch from network if cache is empty
        let result = await timetablesService.fetchTimetable()
        switch result {
        case .success(let response):
            await self.saveTimetables(response)
            await MainActor.run {
                hasError = false
            }
            print("Timetable cache refreshed successfully.")
            print(response)
        case .failure(let error):
            await MainActor.run {
                hasError = true
            }
            print("Failed to refresh Timetable cache: \(error.localizedDescription)")
        }
    }
}
