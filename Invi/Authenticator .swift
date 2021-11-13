//
//  Authenticator .swift
//  Invi
//
//  Created by Michal Gorzalczany on 30/05/2021.
//

import Foundation
import Combine

protocol AuthenticatorType {
    var state: CurrentValueSubject<Authenticator.State, Never> { get }
    var token: String? { get }
    func login(email: String, password: String) async throws
    func register(email: String, password: String) async throws
    func logout()
}

final class Authenticator: AuthenticatorType, ObservableObject {
    typealias Dependencies = HasWebService & HasAppConfiguration

    enum State {
        case loggedIn
        case loggedOut
    }

    var state: CurrentValueSubject<Authenticator.State, Never>

    private(set) var token: String? {
        didSet {
            assert(Thread.isMainThread)
            print("Changing token from \(String(describing: oldValue)) to \(String(describing: token))")
            guard token != oldValue else { return }
            if token != nil {
                state.value = .loggedIn
                // TODO: Save to keychain
                UserDefaults.standard.set(token, forKey: "token")
            } else {
                state.value = .loggedOut
                UserDefaults.standard.removeObject(forKey: "token")
            }
        }
    }

    private let dependencies: Dependencies
    private var loginCancellable: AnyCancellable?
    private var registerCancellable: AnyCancellable?

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
        if let storedToken = UserDefaults.standard.string(forKey: "token") {
            token = storedToken
            state = CurrentValueSubject(.loggedIn)
        } else {
            state = CurrentValueSubject(.loggedOut)
        }
    }

    enum LoginError: Swift.Error {
        case invalidCredentials
        case notLoggedOut
        case other(Error)
    }

    func login(email: String, password: String) async throws {
        guard state.value == .loggedOut else {
            assertionFailure("Trying to login when already logged in or evaluating.")
            throw LoginError.notLoggedOut
        }
        do {
            let token = try await LoginEndpointService.login(with: email, password: password, dependencies: dependencies)
            self.token = token

        } catch {
            if let error = error as? WebService.Error, case let .httpError(statusCode) = error, statusCode == 400 {
                throw LoginError.invalidCredentials
            } else {
                throw LoginError.other(error)
            }
        }
    }

    func logout() {
        assert(state.value.isLoggedIn)
        token = nil
    }

    func register(email: String, password: String) async throws {
        try await RegisterEndpointService.register(with: email, password: password, dependencies: dependencies)
    }
}

private enum LoginEndpointService {
    static func login(with email: String, password: String, dependencies: HasWebService & HasAppConfiguration) async throws -> String {
        let request = URLRequest(url: dependencies.configuration.apiEnviroment.baseURL.appendingPathComponent("auth/login"))
        let body = LoginRequestBody(email: email, password: password)
        let loginResponse: LoginResponse = try await dependencies.webService.post(model: body, request: request, authenticate: false).value
        return loginResponse.token
    }

    private struct LoginResponse: Decodable {
        let token: String
    }

    private struct LoginRequestBody: Encodable {
        let email: String
        let password: String
    }
}

private enum RegisterEndpointService {
    static func register(with email: String, password: String, dependencies: HasWebService & HasAppConfiguration) async throws {
        let request = URLRequest(url: dependencies.configuration.apiEnviroment.baseURL.appendingPathComponent("register"))

        let body = RegisterRequestBody(deviceId: "iOS-test", email: email, password: password) // TODO: Device id

        let _: RegisterResponse = try await dependencies.webService.post(model: body, request: request, authenticate: false).value
    }

    private struct RegisterResponse: Decodable {
        let userId: String
    }

    private struct RegisterRequestBody: Encodable {
        let deviceId: String
        let email: String
        let password: String
    }
}

extension Authenticator.State {
    var isLoggedIn: Bool {
        return self == .loggedIn
    }
}
