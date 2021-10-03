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
    func login(email: String, password: String) -> AnyPublisher<Void, Authenticator.LoginError>
    func register(email: String, password: String) -> AnyPublisher<Void, Error>
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

    func login(email: String, password: String) -> AnyPublisher<Void, LoginError> {
        guard state.value == .loggedOut else {
            assertionFailure("Trying to login when already logged in or evaluating.")
            return Fail(error: LoginError.notLoggedOut).eraseToAnyPublisher()
        }
        return LoginEndpointService.login(with: email, password: password, dependencies: dependencies)
            .mapError { error in
                if let error = error as? WebService.Error, case let .httpError(statusCode) = error, statusCode == 400 {
                    return LoginError.invalidCredentials
                } else {
                    return LoginError.other(error)
                }
            }
            .receive(on: DispatchQueue.main)
            .handleEvents(receiveOutput: { [weak self] token in
                self?.token = token
            })
            .map { _ in () }
            .eraseToAnyPublisher()
    }

    func logout() {
        token = nil
    }

    func register(email: String, password: String) -> AnyPublisher<Void, Error> {
        return RegisterEndpointService.register(with: email, password: password, dependencies: dependencies)
    }
}

private enum LoginEndpointService {
    static func login(with email: String, password: String, dependencies: HasWebService & HasAppConfiguration) -> AnyPublisher<String, Error> {
        var request = URLRequest(url: dependencies.configuration.apiEnviroment.baseURL.appendingPathComponent("auth/login"))
        let body = LoginRequestBody(email: email, password: password)
        let data: Data
        do {
            data = try JSONEncoder().encode(body)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        request.httpBody = data
        request.httpMethod = "POST"
        let resource = WebResource<LoginResponse>(request: request)
        return dependencies.webService.load(resource: resource)
            .map { response in
                return response.token
            }
            .eraseToAnyPublisher()
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
    static func register(with email: String, password: String, dependencies: HasWebService & HasAppConfiguration) -> AnyPublisher<Void, Error> {
        var request = URLRequest(url: dependencies.configuration.apiEnviroment.baseURL.appendingPathComponent("register"))
        let body = RegisterRequestBody(deviceId: "iOS-test", email: email, password: password) // TODO: Device id
        let data: Data
        do {
            data = try JSONEncoder().encode(body)
        } catch {
            return Fail(error: error).eraseToAnyPublisher()
        }
        request.httpBody = data
        request.httpMethod = "POST"
        let resource = WebResource<RegisterResponse>(request: request)
        return dependencies.webService.load(resource: resource)
            .map { response in
                 print("User registered with id: \(response.userId)")
                 return ()
            }
            .eraseToAnyPublisher()
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
