//
//  AppConfiguration.swift
//  Invi
//
//  Created by Marcin Mucha on 03/10/2021.
//

import Foundation

struct AppConfiguration {
    let buildConfiguration: BuildConfiguration = .live
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
