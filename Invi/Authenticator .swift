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
    func login(email: String, password: String)
    func register(email: String, password: String) -> AnyPublisher<Void, Error>
    func logout()
}

final class Authenticator: AuthenticatorType, ObservableObject {
    typealias Dependencies = HasWebService

    enum State {
        case none // TOOD: Avoid this state by reading from keychain
        case loggedIn
        case loggedOut
        case evaluating
    }

    var state: CurrentValueSubject<Authenticator.State, Never>

    private(set) var token: String? {
        didSet {
            assert(Thread.isMainThread)
            print("Changing token from \(String(describing: oldValue)) to \(String(describing: token))")
            guard token != oldValue else { return }
            if let token = token {
                state.value = .loggedIn
                // TODO: Save to keychain
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
        state = CurrentValueSubject(.none)
    }

    func login(email: String, password: String) {
        guard state.value != .loggedIn else { fatalError() }
        state.value = .evaluating
        loginCancellable?.cancel()
        loginCancellable = LoginEndpointService.login(with: email, password: password, webService: dependencies.webService)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    print("Login failed with: \(error)")
                case .finished:
                    break
                }
            }, receiveValue: { [weak self] token in
                self?.token = token
            })
    }

    func logout() {
        token = nil
    }

    func register(email: String, password: String) -> AnyPublisher<Void, Error> {
        return RegisterEndpointService.register(with: email, password: password, webService: dependencies.webService)
    }
}

private enum LoginEndpointService {
    static func login(with email: String, password: String, webService: WebServiceType) -> AnyPublisher<String, Error> {
        var request = URLRequest(url: URL(string: "https://backend.invi.click/api/v1/auth/login")!)
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
        return webService.load(resource: resource)
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
    static func register(with email: String, password: String, webService: WebServiceType) -> AnyPublisher<Void, Error> {
        var request = URLRequest(url: URL(string: "https://backend.invi.click/api/v1/register")!)
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
        return webService.load(resource: resource)
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
