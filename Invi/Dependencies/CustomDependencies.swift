//
//  CustomDependencies.swift
//  Invi
//
//  Created by Marcin Mucha on 12/11/2021.
//

import Foundation
import InviClient
import InviAuthenticator

#if DEBUG
final class CustomDependencies: InviDependencies {
    let inviClient: InviClient
    let authenticator: Authenticator
    let configuration: AppConfiguration
    let application: Application

    init(inviClient: InviClient? = nil,
         authenticator: Authenticator? = nil,
         configuration: AppConfiguration? = nil,
         application: Application? = nil
    ) {
        let liveDependencies = LiveDependencies()
        self.inviClient = inviClient ?? liveDependencies.inviClient
        self.authenticator = authenticator ?? liveDependencies.authenticator
        self.configuration = configuration ?? liveDependencies.configuration
        self.application = application ?? liveDependencies.application
    }
}
#endif
