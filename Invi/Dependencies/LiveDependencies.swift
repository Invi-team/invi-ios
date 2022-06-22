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
    lazy var inviClient: InviClient = .live(configuration: .init(
        environment: { [unowned self] in
            self.configuration.inviClientEnvironment
        },
        authenticatedSession: { [weak self] in
            self?.authenticator.state.value.authenticatedSession
        }
    ))
    
    lazy var authenticator: Authenticator = .live(configuration: .init(
        environment: { [unowned self] in self.configuration.inviAuthenticatorEnvironment }
    ))
    
    lazy var configuration = AppConfiguration(buildConfiguration: .live, dependencies: self)
    let application: Application = .live
    let userDefaults: UserDefaultsType = UserDefaults.standard
}
