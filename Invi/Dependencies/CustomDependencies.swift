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

    init(inviClient: InviClient? = nil,
         authenticator: Authenticator? = nil,
         configuration: AppConfiguration? = nil) {
        let liveDependencies = LiveDependencies()
        self.inviClient = inviClient ?? liveDependencies.inviClient
        self.authenticator = authenticator ?? liveDependencies.authenticator
        self.configuration = configuration ?? liveDependencies.configuration
    }
}
