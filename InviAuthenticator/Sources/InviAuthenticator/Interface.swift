//
//  Interface.swift
//  
//
//  Created by Marcin Mucha on 13/11/2021.
//

import Foundation
import Combine
import SwiftUI

public struct Authenticator {
    public var state: CurrentValueSubject<Authenticator.State, Never>
    public var login: (_ email: String, _ password: String) async throws -> Void
    public var register: (_ email: String, _ password: String) async throws -> Void
    public var logout: () -> Void

    public enum State: Equatable {
        case loggedIn(token: String, user: User?)
        case loggedOut
    }

    public enum LoginError: Error {
        case invalidCredentials
        case notLoggedOut
        case keychain(Error)
        case other(Error)
    }

    public enum RegisterError: Error {
        case emailInvalid
        case emailAlreadyTaken
        case passwordTooShort
        case other(Error)
    }

    public struct Configuration {
        let environment: () -> ApiEnvironment
        public init(environment: @escaping () -> ApiEnvironment) {
            self.environment = environment
        }

        public static let prod = Configuration { .prod }
    }

    public enum ApiEnvironment: String {
        case prod
        case stage = "dev"

        var baseURL: URL {
            return URL(string: "https://\(rawValue).invi.click/api/v1/")!
        }
    }
}

public struct User: Equatable, Codable {
    public let id: String
    public let email: String
    public let name: String?
    public let surname: String?
}

public struct UserTokens: Equatable, Codable {
    let accessToken: String
    let refreshToken: String
}
