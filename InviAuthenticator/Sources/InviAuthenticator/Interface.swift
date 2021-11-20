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

    public enum LoginError: Swift.Error {
        case invalidCredentials
        case notLoggedOut
        case keychain(Error)
        case other(Error)
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
