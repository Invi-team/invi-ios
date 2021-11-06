//
//  AppConfiguration.swift
//  Invi
//
//  Created by Marcin Mucha on 03/10/2021.
//

import Foundation

struct AppConfiguration {
    let apiEnviroment: ApiEnvironment = .prod
}

enum ApiEnvironment: String {
    case stage
    case prod

    var baseURL: URL {
        return URL(string: "https://\(rawValue).invi.click/api/v1/")!
    }
}
