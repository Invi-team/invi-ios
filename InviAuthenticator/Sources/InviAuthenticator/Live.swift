//
//  Live.swift
//  
//
//  Created by Marcin Mucha on 13/11/2021.
//

import Foundation
import Combine
import WebService
import CasePaths

extension Authenticator {
    // swiftlint:disable:next function_body_length
    public static func live(environment: ApiEnvironment) -> Self {
        let webService = WebService()
        let keychainStorage = KeychainStorage()

        let state: CurrentValueSubject<Authenticator.State, Never>
        if let storedToken = try? keychainStorage.getToken() {
            state = CurrentValueSubject(.loggedIn(token: storedToken, user: nil))
        } else {
            state = CurrentValueSubject(.loggedOut)
        }

        @Sendable func user(for token: String) async throws -> User {
            let url = environment.baseURL.appendingPathComponent("user")
            var request = URLRequest(url: url)
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            return try await webService.get(request: request).value
        }

        Task { @MainActor in
            for await currentState in state.eraseToAnyPublisher().values {
                if case .loggedIn(let token, let currentUser) = currentState, currentUser == nil {
                    do {
                        let user = try await user(for: token)
                        state.value = .loggedIn(token: token, user: user)
                    } catch {
                        debugPrint("Failed fetching User with error: \(error)")
                    }
                }
            }
        }

        return Authenticator(
            state: state,
            login: { email, password in
                guard state.value.isLoggedOut else {
                    assertionFailure("Trying to login when already logged in.")
                    throw Authenticator.LoginError.notLoggedOut
                }
                do {
                    let request = URLRequest(url: environment.baseURL.appendingPathComponent("auth/login"))
                    let body = LoginRequestBody(email: email, password: password)
                    let loginResponse: LoginResponse = try await webService.post(model: body, request: request).value
                    try keychainStorage.add(token: loginResponse.token)
                    state.value = .loggedIn(token: loginResponse.token, user: nil)
                } catch {
                    if let error = error as? WebService.Error, case let .httpError(statusCode, _) = error, statusCode == 400 {
                        throw Authenticator.LoginError.invalidCredentials
                    } else if let error = error as? KeychainStorage.Error {
                        throw Authenticator.LoginError.keychain(error)
                    } else {
                        throw Authenticator.LoginError.other(error)
                    }
                }
            },
            register: { email, password in
                let request = URLRequest(url: environment.baseURL.appendingPathComponent("register"))
                let body = RegisterRequestBody(deviceId: "iOS-test", email: email, password: password) // TODO: Device id
                let _: RegisterResponse = try await webService.post(model: body, request: request).value
            },
            logout: {
                state.value = .loggedOut
                do {
                    try keychainStorage.removeToken()
                } catch {
                    debugPrint(error)
                }
            }
        )
    }
}

private struct LoginResponse: Decodable {
    let token: String
}

private struct LoginRequestBody: Encodable {
    let email: String
    let password: String
}

private struct RegisterResponse: Decodable {
    let userId: String
}

private struct RegisterRequestBody: Encodable {
    let deviceId: String
    let email: String
    let password: String
}

extension Authenticator.State {
    public var isLoggedOut: Bool {
        (/Authenticator.State.loggedOut).extract(from: self) != nil
    }

    public var token: String? {
        guard case .loggedIn(let token, _) = self else { return nil }
        return token
    }
}
