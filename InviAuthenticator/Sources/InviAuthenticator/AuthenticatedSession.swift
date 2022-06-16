//
//  AuthenticatedSession.swift
//  
//
//  Created by Marcin Mucha on 16/06/2022.
//

import Foundation
import WebService

protocol TokenControllerType: Actor {
    var userTokens: UserTokens { get }
    func set(tokens: UserTokens)
}

actor TokenController: TokenControllerType {
    private(set) var userTokens: UserTokens {
        didSet {
            // TODO: Handle saving tokens
        }
    }
    
    private let keychainStorage: KeychainStorageType
    
    init(userTokens: UserTokens, keychainStorage: KeychainStorageType) {
        self.userTokens = userTokens
        self.keychainStorage = keychainStorage
        
        // TODO: Handle saving tokens
    }
    
    func set(tokens: UserTokens) {
        userTokens = tokens
    }
}

final class AuthenticatedSession {
    let tokenController: TokenControllerType
    let webService: WebServiceType
    let configuration: Authenticator.Configuration
    
    init(
        tokenController: TokenControllerType,
        webService: WebServiceType,
        configuration: Authenticator.Configuration
    ) {
        self.tokenController = tokenController
        self.webService = webService
        self.configuration = configuration
    }
    
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, httpResponse) = try await mainRequestData(for: request)
        if httpResponse.statusCode == 401 {
            do {
                let tokens = try await refreshToken()
                await tokenController.set(tokens: tokens)
                return try await mainRequestData(for: request)
            } catch {
                return (data, httpResponse)
            }
        } else {
            return (data, httpResponse)
        }
    }
    
    private func mainRequestData(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let accessToken = await tokenController.userTokens.accessToken
        let (data, response) = try await webService.data(for: request.authenticated(with: accessToken), delegate: nil)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AuthenticatedSessionError.invalidResponse
        }
        return (data, httpResponse)
    }
    
    private enum AuthenticatedSessionError: Error {
        case encodingRefreshTokenFailure
        case invalidResponse
        case refreshTokenError(statusCode: Int)
    }
    
    private func refreshToken() async throws -> UserTokens {
        let url = configuration.environment().baseURL
            .appendingPathComponent("auth")
            .appendingPathComponent("refresh-session")
        let refreshToken = await tokenController.userTokens.refreshToken
        return try await webService.post(model: RefreshRequestBody(refreshToken: refreshToken), request: URLRequest(url: url))
    }
    
    private func authenticatedRequest(_ request: URLRequest, tokens: UserTokens?) -> URLRequest {
        var requestCopy = request
        if let bearer = tokens?.accessToken {
            requestCopy.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
        }
        return requestCopy
    }
}

private extension URLRequest {
    func authenticated(with accessToken: String) -> URLRequest {
        var request = self
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return request
    }
}

private struct RefreshRequestBody: Encodable {
    let refreshToken: String
}

