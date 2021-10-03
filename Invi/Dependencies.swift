//
//  Dependencies.swift
//  Invi
//
//  Created by Marcin Mucha on 20/05/2021.
//

import Foundation

typealias InviDependencies = HasWebService & HasAuthenticator & HasAppConfiguration

protocol HasWebService {
    var webService: WebServiceType { get }
}

protocol HasAuthenticator {
    var authenticator: AuthenticatorType { get }
}

protocol HasAppConfiguration {
    var configuration: AppConfiguration { get }
}

final class Dependencies: InviDependencies {
    let webService: WebServiceType = WebService()
    lazy var authenticator: AuthenticatorType = Authenticator(dependencies: self)
    let configuration = AppConfiguration()
}
