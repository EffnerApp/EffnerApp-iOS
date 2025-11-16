//
//  ExamsCache.swift
//  EffnerApp
//
//  Created by Luis Bros on 31.08.25.
//
import Foundation
import Combine

class ExamsCache: ObservableObject {
    static let shared = ExamsCache()
    @Published var cachedExamResponse: ExamsResponse = ExamsResponse(className: "nil", exams: []) {
        didSet {
            objectWillChange.send()
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        watchUserSession()
    }

    public func saveExams(_ examResponse: ExamsResponse) {
        DispatchQueue.main.async {
            self.cachedExamResponse = examResponse
        }
    }

    private func watchUserSession() {
        UserSession.shared.objectWillChange
            .sink { [weak self] _ in
                guard let self = self else { return }
                Task { @MainActor in
                    await self.refreshCache()
                }
            }
            .store(in: &cancellables)
    }

    public func refreshCache() async {
        if(UserSession.shared.user == nil || !UserSession.shared.user!.isAuthorized) {
            return
        }
        if(UserSession.shared.user!.klass == "test") {
            self.saveExams(MockExam.mockExams)
            print("Exams cache refreshed with mock data.")
            return
        }
        
        let examsService = ExamsService()
        
        // Fetch from network if cache is empty
        let result = await examsService.fetchExams()
        switch result {
            case .success(let response):
                self.saveExams(response)
                print("Exams cache refreshed successfully.")
            case .failure(let error):
                print("Failed to refresh exams cache: \(error.localizedDescription)")
        }
    }
}
