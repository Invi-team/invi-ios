//
//  AuthenticatedSession.swift
//  
//
//  Created by Marcin Mucha on 16/06/2022.
//

import Foundation
import WebService

public final class AuthenticatedSession: Equatable, URLSessionType {
    public func data(for request: URLRequest, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse) {
        return try await data(for: request)
    }
    
    let tokenController: TokenControllerType
    let webService: WebServiceType
    let configuration: Authenticator.Configuration
    let onRefreshTokenInvalid: () -> Void
    
    init(
        tokenController: TokenControllerType,
        webService: WebServiceType,
        configuration: Authenticator.Configuration,
        onRefreshTokenInvalid: @escaping () -> Void
    ) {
        self.tokenController = tokenController
        self.webService = webService
        self.configuration = configuration
        self.onRefreshTokenInvalid = onRefreshTokenInvalid
    }
    
    public static func == (lhs: AuthenticatedSession, rhs: AuthenticatedSession) -> Bool {
        return false
    }
    
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let (data, httpResponse) = try await mainRequestData(for: request)
        if httpResponse.statusCode == 401 {
            do {
                let tokens = try await refreshToken()
                await tokenController.set(tokens: tokens)
                debugPrint("Access token successfully refreshed.")
                return try await mainRequestData(for: request)
            } catch {
                if let httpError = error as? WebService.Error, case .httpError(let statusCode, _, let metadata) = httpError, statusCode == 400, metadata.contains("REFRESH_TOKEN_INVALID") {
                    debugPrint("Failed refreshing the token because the refresh token is invalid.")
                    onRefreshTokenInvalid()
                }
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
        case invalidResponse
    }
    
    private func refreshToken() async throws -> UserTokens {
        let url = configuration.environment().baseURL
            .appendingPathComponent("auth")
            .appendingPathComponent("refresh-session")
        let refreshToken = await tokenController.userTokens.refreshToken
        debugPrint("Attempting to refresh the accessToken...")
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
