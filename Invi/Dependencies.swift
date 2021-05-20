//
//  Dependencies.swift
//  Invi
//
//  Created by Marcin Mucha on 20/05/2021.
//

import Foundation

typealias InviDependencies = HasWebService

protocol HasWebService {
    var webService: WebServiceType { get }
}

final class Dependencies: InviDependencies {
    let webService: WebServiceType = WebService()
}
