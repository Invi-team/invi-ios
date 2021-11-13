//
//  InviDependencies.swift
//  Invi
//
//  Created by Marcin Mucha on 12/11/2021.
//
import InviClient
import InviAuthenticator

typealias InviDependencies = HasAuthenticator & HasAppConfiguration & HasInviClient

protocol HasInviClient {
    var inviClient: InviClient { get }
}

protocol HasAuthenticator {
    var authenticator: Authenticator { get }
}

protocol HasAppConfiguration {
    var configuration: AppConfiguration { get }
}
