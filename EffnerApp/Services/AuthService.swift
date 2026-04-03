//
//  AuthenticationService.swift
//  EffnerApp
//
//  Created by Luis Bros on 21.07.25.
//
import Foundation
import OSLog

class AuthService : ObservableObject {
    private static let logger = Log.auth
    @Published var error: NetworkError?
    
    private let networkManager : NetworkManager
    
    init(networkManager: NetworkManager = NetworkManager.shared) {
        self.networkManager = networkManager
    }
    
    func register(username: String, password: String, klasses: [String]) async -> Result<User, NetworkError> {
        let auth = Authentication.ssbBasic(username: username, password: password)
        let deviceToken = await NotificationService.shared.deviceToken
        let ssbUserRequest = SSBUserRequest(deviceToken: deviceToken, classes: klasses)
        
        do {
            let ssbUserResponse: SSBUserResponse = try await networkManager.fetch(
                from: CreateUserEndpoint(ssbUserRequest: ssbUserRequest, auth: auth)
            )
            
            guard let ssbToken = ssbUserResponse.token else {
                self.error = .serverError(statusCode: 500, msg: "Server did not return a token on user creation.")
                return .failure(self.error!)
            }
            
            let user = User(
                ssbId: ssbUserResponse.id,
                ssbToken: ssbToken,
                username: username,
                password: password,
                klasses: klasses,
                isAuthorized: true
            )
            
            await MainActor.run {
                UserSession.shared.setUser(user: user)
            }
            
            user.saveCredentials()
            user.saveKlasses()
            user.saveSSBCredentials()
            
            Self.logger.info("SSB user created successfully: \(ssbUserResponse.id)")
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
        let auth = user.generateSSBTokenAuth()
        
        do {
            let _: SSBUserResponse = try await networkManager.fetch(
                from: GetUserEndpoint(userId: user.ssbId, auth: auth)
            )
            return .success(true)
        } catch let networkError as NetworkError {
            self.error = networkError
            return .failure(self.error!)
        } catch {
            self.error = .unknownError(statusCode: 0, msg: error.localizedDescription)
            return .failure(self.error!)
        }
    }


    

}
