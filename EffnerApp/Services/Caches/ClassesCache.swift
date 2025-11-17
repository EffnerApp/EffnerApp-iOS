//
//  ClassesCache.swift
//  EffnerApp
//
//  Created by Luis Bros on 31.08.25.
//
import Foundation
import Combine


class ClassesCache: ObservableObject {
    static let shared = ClassesCache()
    @Published var cachedClasses: [String] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    private func saveClasses(_ classes: [String]) {
        DispatchQueue.main.async {
            self.cachedClasses = classes
        }
    }

    public func refreshCache() async {
        let classesService = ClassesService()
        
        // Fetch from network if cache is empty
        let result = await classesService.fetchClasses()
        switch result {
        case .success(let response):
            self.saveClasses(response)
            print("Classes cache refreshed successfully.")
        case .failure(let error):
            print("Failed to refresh Classes cache: \(error.localizedDescription)")
        }
    }
}
