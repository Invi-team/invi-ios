//
//  AppConfiguration.swift
//  Invi
//
//  Created by Marcin Mucha on 03/10/2021.
//

import Foundation
import InviAuthenticator
import InviClient

struct AppConfiguration {
    typealias Dependencies = HasUserDefaults

    private let dependencies: Dependencies

    let buildConfiguration: BuildConfiguration

    init(buildConfiguration: BuildConfiguration, dependencies: Dependencies) {
        self.buildConfiguration = buildConfiguration
        self.dependencies = dependencies
    }
}

extension AppConfiguration {
    var inviAuthenticatorEnvironment: Authenticator.ApiEnvironment {
        switch buildConfiguration {
        case .release(.appStore):
            return .prod
        default:
            return dependencies.userDefaults.bool(forKey: .apiDevEnvrionmentEnabled) == true ? .stage : .prod
        }
    }

    var inviClientEnvironment: InviClient.ApiEnvironment {
        switch buildConfiguration {
        case .release(.appStore):
            return .prod
        default:
            return dependencies.userDefaults.bool(forKey: .apiDevEnvrionmentEnabled) == true ? .stage : .prod
        }
    }

    var isAppStore: Bool {
        buildConfiguration == .release(.appStore)
    }
}

enum BuildConfiguration: Equatable {
    enum DeploymentEnvironment {
        case testFlight, appStore, adHoc
    }

    case debug
    case release(DeploymentEnvironment)

    static var live: BuildConfiguration {
        #if DEBUG
            return .debug
        #else
            if Bundle.main.path(forResource: "embedded", ofType: "mobileprovision") != nil {
                return .release(.adHoc)
            } else {
                if Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt" {
                    return .release(.testFlight)
                } else {
                    return .release(.appStore)
                }
            }
        #endif
    }
}
