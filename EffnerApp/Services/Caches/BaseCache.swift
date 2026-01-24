//
//  BaseCache.swift
//  EffnerApp
//
//  Created by Luis Bros on 17.11.25.
//

import Foundation
import Combine

/// Protokoll für Cache-Objekte, die in BaseContentView verwendet werden
protocol CacheProtocol: ObservableObject {
    var hasError: Bool { get }
    var isEmpty: Bool { get }
    func refreshCache() async
}

/// Generische Basis-Klasse für alle Caches mit State Machine Pattern
class BaseCache<ResponseType>: ObservableObject, CacheProtocol {
    
    enum LoadState {
        case idle
        case loading
        case loaded(ResponseType)
        case error
    }
    
    @Published var loadState: LoadState = .idle
    
    var cachedResponse: ResponseType? {
        if case .loaded(let response) = loadState {
            return response
        }
        return nil
    }
    
    var hasError: Bool {
        if case .error = loadState {
            return true
        }
        // Subklassen können überschreiben, um zusätzliche Error-Bedingungen zu prüfen (z.B. leere Daten)
        return false
    }
    
    var isEmpty: Bool {
        switch loadState {
        case .idle, .loading:
            return true
        case .loaded:
            return false
        case .error:
            return true
        }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        watchUserSession()
    }
    
    // MARK: - Public Methods
    
    /// Speichert die Response im Cache
    public func saveResponse(_ response: ResponseType) {
        DispatchQueue.main.async { [weak self] in
            self?.loadState = .loaded(response)
        }
    }
    
    /// Beobachtet UserSession-Änderungen und aktualisiert Cache
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
    
    /// Aktualisiert den Cache - muss von Subklassen implementiert werden
    public func refreshCache() async {
        fatalError("refreshCache() must be overridden by subclass")
    }
    
    // MARK: - Helper Methods für Subklassen
    
    /// Prüft, ob User autorisiert ist
    func isUserAuthorized() -> Bool {
        guard let user = UserSession.shared.user else { return false }
        return user.isAuthorized
    }
    
    /// Setzt Loading-State
    func setLoading() async {
        await MainActor.run { [weak self] in
            self?.loadState = .loading
        }
    }
    
    /// Setzt Error-State
    func setError() async {
        await MainActor.run { [weak self] in
            self?.loadState = .error
        }
    }
    
    /// Gibt Mock-Daten zurück, falls User "test" Klasse hat
    func shouldUseMockData() -> Bool {
        return UserSession.shared.user?.primaryClass == "test"
    }
}
