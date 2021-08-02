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
    private let session: URLSession

    init(session: URLSession = URLSession.shared) {
        self.session = session
    }

    enum Error: Swift.Error {
        case invalidResponse
        case httpError(Int)
        case invalidData
        case terminated
    }

    func load<T: Decodable>(resource: WebResource<T>) -> AnyPublisher<T, Swift.Error> {
        return load(request: resource.request)
            .decode(type: T.self, decoder: JSONDecoder())
            .eraseToAnyPublisher()
    }

    private func load(request: URLRequest) -> AnyPublisher<Data, Swift.Error> {
        debugPrint("Loading request with url: \(request.url!.absoluteString)") // TODO: Remove when logger in place
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
}
