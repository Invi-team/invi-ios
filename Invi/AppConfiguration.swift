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

    static let basePath = "https://{env}.invi.click/api/v1/"

    var baseURL: URL {
        return URL(string: Self.basePath.replacingOccurrences(of: "{env}", with: rawValue))!
    }
}
