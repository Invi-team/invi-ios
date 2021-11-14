//
//  Dependencies.swift
//  Invi
//
//  Created by Marcin Mucha on 20/05/2021.
//

import Foundation
import InviClient
import InviAuthenticator

final class LiveDependencies: InviDependencies {
    lazy var inviClient: InviClient = .live(environment: .prod, userToken: { [weak self] in self?.authenticator.state.value.token })
    let authenticator: Authenticator = .live(environment: .prod)
    let configuration = AppConfiguration()
}