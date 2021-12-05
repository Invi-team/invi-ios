//
//  CustomDependencies.swift
//  Invi
//
//  Created by Marcin Mucha on 12/11/2021.
//

import Foundation
import InviClient
import InviAuthenticator

final class CustomDependencies: InviDependencies {
    let inviClient: InviClient
    let authenticator: Authenticator
    let configuration: AppConfiguration
    let application: Application
    let userDefaults: UserDefaultsType

    init(inviClient: InviClient? = nil,
         authenticator: Authenticator? = nil,
         configuration: AppConfiguration? = nil,
         application: Application? = nil,
         userDefaults: UserDefaultsType? = nil
    ) {
        let liveDependencies = LiveDependencies()
        self.inviClient = inviClient ?? liveDependencies.inviClient
        self.authenticator = authenticator ?? liveDependencies.authenticator
        self.configuration = configuration ?? liveDependencies.configuration
        self.application = application ?? liveDependencies.application
        self.userDefaults = userDefaults ?? liveDependencies.userDefaults
    }
}
