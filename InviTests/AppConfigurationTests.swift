//
//  AppConfiguration.swift
//  
//
//  Created by Marcin Mucha on 05/12/2021.
//

import Foundation
import XCTest
@testable import Invi
import InviClient
import InviAuthenticator

final class AppConfigurationTests: XCTestCase {
    class FakeDependencies: AppConfiguration.Dependencies {
        let fakeuserDefaults = FakeUserDefaults()
        lazy var userDefaults: UserDefaultsType = fakeuserDefaults
    }

    let dependencies = FakeDependencies()

    func testAppStoreEnvironments() {
        dependencies.fakeuserDefaults.set(bool: true, forKey: .apiDevEnvrionmentEnabled)
        let configuration = AppConfiguration(buildConfiguration: .release(.appStore), dependencies: dependencies)
        XCTAssertEqual(configuration.inviClientEnvironment, .prod)
        XCTAssertEqual(configuration.inviAuthenticatorEnvironment, .prod)
    }

    func testTestFlightEnvironments_whenDebugOptionEnabled() {
        dependencies.fakeuserDefaults.set(bool: true, forKey: .apiDevEnvrionmentEnabled)
        let configuration = AppConfiguration(buildConfiguration: .release(.testFlight), dependencies: dependencies)
        XCTAssertEqual(configuration.inviClientEnvironment, .stage)
        XCTAssertEqual(configuration.inviAuthenticatorEnvironment, .stage)
    }

    func testTestFlightEnvironments_whenDebugOptionDisabled() {
        dependencies.fakeuserDefaults.set(bool: false, forKey: .apiDevEnvrionmentEnabled)
        let configuration = AppConfiguration(buildConfiguration: .release(.testFlight), dependencies: dependencies)
        XCTAssertEqual(configuration.inviClientEnvironment, .prod)
        XCTAssertEqual(configuration.inviAuthenticatorEnvironment, .prod)
    }

    func testDebugEnvironments_whenDebugOptionEnabled() {
        dependencies.fakeuserDefaults.set(bool: true, forKey: .apiDevEnvrionmentEnabled)
        let configuration = AppConfiguration(buildConfiguration: .debug, dependencies: dependencies)
        XCTAssertEqual(configuration.inviClientEnvironment, .stage)
        XCTAssertEqual(configuration.inviAuthenticatorEnvironment, .stage)
    }

    func testDebugEnvironments_whenDebugOptionDisabled() {
        dependencies.fakeuserDefaults.set(bool: false, forKey: .apiDevEnvrionmentEnabled)
        let configuration = AppConfiguration(buildConfiguration: .debug, dependencies: dependencies)
        XCTAssertEqual(configuration.inviClientEnvironment, .prod)
        XCTAssertEqual(configuration.inviAuthenticatorEnvironment, .prod)
    }
}
