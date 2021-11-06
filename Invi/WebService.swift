//
//  WebService.swift
//  Invi
//
//  Created by Marcin Mucha on 20/05/2021.
//

import Foundation
import Combine

protocol WebServiceType {
    func load<T: Decodable>(resource: WebResource<T>) -> AnyPublisher<T, Swift.Error>
}

final class WebService: WebServiceType {
    typealias Dependencies = HasAuthenticator

    private let session: URLSession
    private let dependencies: Dependencies

    init(session: URLSession = URLSession.shared, dependencies: Dependencies) {
        self.session = session
        self.dependencies = dependencies
    }

    enum Error: Swift.Error {
        case invalidResponse
        case httpError(Int)
        case invalidData
        case terminated
    }

    func load<T: Decodable>(resource: WebResource<T>) -> AnyPublisher<T, Swift.Error> {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return load(request: resource.request, authenticated: resource.authenticated)
            .decode(type: T.self, decoder: decoder)
            .handleEvents(receiveCompletion: { completion in
                switch completion {
                case .failure(let error): debugPrint(error)
                case .finished: break
                }
            })
            .eraseToAnyPublisher()
    }

    private func load(request: URLRequest, authenticated: Bool) -> AnyPublisher<Data, Swift.Error> {
        debugPrint("Loading request with url: \(request.url!.absoluteString)") // TODO: Remove when logger in place
        var request = request
        if authenticated, let token = dependencies.authenticator.token {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        return session.dataTaskPublisher(for: request)
            .tryMap { data, response in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw Error.invalidResponse
                }
                guard 200..<400 ~= httpResponse.statusCode else {
                    throw Error.httpError(httpResponse.statusCode)
                }
                return data
            }
            .eraseToAnyPublisher()
    }
}

struct WebResource<T: Decodable> {
    let request: URLRequest
    let authenticated: Bool

    init(request: URLRequest, authenticated: Bool = false) {
        self.request = request
        self.authenticated = authenticated
    }
}
