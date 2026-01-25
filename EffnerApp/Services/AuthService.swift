//
//  AuthenticationService.swift
//  EffnerApp
//
//  Created by Luis Bros on 21.07.25.
//
import Foundation

class AuthService : ObservableObject {
    @Published var error: NetworkError?
    
    private let networkManager : NetworkManager
    
    init(networkManager: NetworkManager = NetworkManager.shared) {
        self.networkManager = networkManager
    }
    
    func login(username: String, password: String, klasses: [String]) async -> Result<User, NetworkError> {
        let authentication = Authentication(username: username, password: password)
        
        do {
            let loginResponse: LoginResponse = try await networkManager.fetch(from: AuthEndpoint(auth: authentication))
            guard loginResponse.status.login else {
                self.error = .clientError(statusCode: 403)
                return .failure(self.error!)
            }
            
            let user = User(username: username, password: password, klasses: klasses, isAuthorized: true)
            
            // Update on main thread
            await MainActor.run {
                UserSession.shared.user = user
            }
            
            user.saveCredentials()
            user.saveKlasses()
            
            return .success(user)
        } catch let networkError as NetworkError {
            self.error = networkError
            return .failure(self.error!)
        } catch {
            self.error = .unknownError(statusCode: 0)
            return .failure(self.error!)
        }
    }
    
    func authorize(user: User) async -> Result<Bool, NetworkError> {
        let auth = user.generateAuth()
        
        do {
            let loginResponse: LoginResponse = try await networkManager.fetch(from: AuthEndpoint(auth: auth))
            guard loginResponse.status.login else {
                self.error = .clientError(statusCode: 403)
                return .failure(self.error!)
            }
            
            return .success(true)
        } catch let networkError as NetworkError {
            self.error = networkError
            return .failure(self.error!)
        } catch(let error) {
            self.error = .unknownError(statusCode: 0, msg: error.localizedDescription)
            return .failure(self.error!)
        }
    }


    

}
