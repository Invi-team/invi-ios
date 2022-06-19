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
    public static func live(configuration: Configuration) -> Self {
        live(
            configuration: configuration,
            webService: WebService(decoder: JSONDecoder.inviDecoder),
            keychainStorage: KeychainStorage()
        )
    }

    // swiftlint:disable:next function_body_length cyclomatic_complexity
    static func live(configuration: Configuration, webService: WebServiceType, keychainStorage: KeychainStorageType) -> Self {
        let state: CurrentValueSubject<Authenticator.State, Never>! = .init(.loggedOut)
        if let tokenController = TokenController(keychainStorage: keychainStorage) {
            let session = AuthenticatedSession(tokenController: tokenController, webService: webService, configuration: configuration, onRefreshTokenInvalid: logout)
            state.value = .loggedIn(session: session, user: nil)
        }
        
        func logout() {
            state.value = .loggedOut
        }

        @Sendable func user(for session: AuthenticatedSession) async throws -> User {
            let url = configuration.environment().baseURL.appendingPathComponent("user")
            return try await webService.get(request: URLRequest(url: url), customSession: session)
        }

        Task { @MainActor in
            for await currentState in state.eraseToAnyPublisher().values {
                if case .loggedIn(let session, let currentUser) = currentState, currentUser == nil {
                    do {
                        let user = try await user(for: session)
                        state.value = .loggedIn(session: session, user: user)
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
                    let request = URLRequest(url: configuration.environment().baseURL.appendingPathComponent("auth/login"))
                    let body = LoginRequestBody(email: email, password: password)
                    let loginResponse: LoginResponse = try await webService.post(model: body, request: request)
                    let userTokens = UserTokens(accessToken: loginResponse.accessToken, refreshToken: loginResponse.refreshToken)
                    let tokenController = TokenController(userTokens: userTokens, keychainStorage: keychainStorage)
                    let authenticatedSession = AuthenticatedSession(tokenController: tokenController, webService: webService, configuration: configuration, onRefreshTokenInvalid: logout)
                    state.value = .loggedIn(session: authenticatedSession, user: nil)
                } catch {
                    debugPrint(error)
                    if let error = error as? WebService.Error, case let .httpError(statusCode, _, _) = error, statusCode == 400 {
                        throw Authenticator.LoginError.invalidCredentials
                    } else if let error = error as? KeychainStorage.Error {
                        throw Authenticator.LoginError.keychain(error)
                    } else {
                        throw Authenticator.LoginError.other(error)
                    }
                }
            },
            register: { email, password in
                let request = URLRequest(url: configuration.environment().baseURL.appendingPathComponent("register"))
                let body = RegisterRequestBody(deviceId: "iOS-test", email: email, password: password) // TODO: Device id
                do {
                    try await webService.post(model: body, request: request)
                } catch {
                    if let error = error as? WebService.Error, case let .httpError(_, _, metadata) = error {
                        if metadata.contains(MetadataValues.passwordTooShort) {
                            throw RegisterError.passwordTooShort
                        } else if metadata.contains(MetadataValues.invalidEmail) {
                            throw RegisterError.emailInvalid
                        } else if metadata.contains(MetadataValues.emailTaken) {
                            throw RegisterError.emailAlreadyTaken
                        }
                    }
                    throw RegisterError.other(error)
                }
            },
            logout: {
                logout()
            }
        )
    }
}

private enum MetadataValues {
    static let passwordTooShort = "PASSWORD_TOO_SHORT"
    static let invalidEmail = "EMAIL_NOT_VALID"
    static let emailTaken = "EMAIL_ALREADY_TAKEN"
}

private struct LoginResponse: Decodable {
    let accessToken: String
    let refreshToken: String
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
}

extension JSONDecoder {
    static var inviDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = JSONDecoder.flexibleDateDecoding
        return decoder
    }
}
