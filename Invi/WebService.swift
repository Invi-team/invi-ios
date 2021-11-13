//
//  WebService.swift
//  Invi
//
//  Created by Marcin Mucha on 20/05/2021.
//

import Foundation
import Combine

protocol WebServiceType {
    func get<T: Decodable>(request: URLRequest, authenticate: Bool) async throws -> Task<T, Swift.Error>
    func post<Model: Encodable, Response: Decodable>(model: Model, request: URLRequest, authenticate: Bool) async throws -> Task<Response, Swift.Error>
    func put<Model: Encodable, Response: Decodable>(model: Model, request: URLRequest, authenticate: Bool) async throws -> Task<Response, Swift.Error>

    // TODO: Remove when API stop returning empty response
    func put<Model: Encodable>(model: Model, request: URLRequest, authenticate: Bool) async throws -> Task<Void, Swift.Error>
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

    func get<T: Decodable>(request: URLRequest, authenticate: Bool) async throws -> Task<T, Swift.Error> {
        Task {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let data: Data
            do {
                data = try await load(request: request, authenticate: authenticate).value
                return try decoder.decode(T.self, from: data)
            } catch {
                debugPrint(error)
                throw error
            }
        }
    }

    func post<Model: Encodable, Response: Decodable>(model: Model, request: URLRequest, authenticate: Bool) async throws -> Task<Response, Swift.Error> {
        try await putOrPost(method: .post, model: model, request: request, authenticate: authenticate)
    }

    func put<Model: Encodable, Response: Decodable>(model: Model, request: URLRequest, authenticate: Bool) async throws -> Task<Response, Swift.Error> {
        try await putOrPost(method: .put, model: model, request: request, authenticate: authenticate)
    }

    func put<Model: Encodable>(model: Model, request: URLRequest, authenticate: Bool) async throws -> Task<Void, Swift.Error> {
        Task {
            let data = try JSONEncoder().encode(model)
            var request = request
            request.httpMethod = "PUT"
            request.httpBody = data

            do {
                _ = try await load(request: request, authenticate: authenticate)
            } catch {
                debugPrint(error)
                throw error
            }
        }
    }

    private enum PostOrPut: String {
        case post = "POST", put = "PUT"
    }

    private func putOrPost<Model: Encodable, Response: Decodable>(method: PostOrPut, model: Model, request: URLRequest, authenticate: Bool) async throws -> Task<Response, Swift.Error> {
        Task {
            let data = try JSONEncoder().encode(model)
            var request = request
            request.httpMethod = method.rawValue
            request.httpBody = data

            let responseData: Data
            do {
                responseData = try await load(request: request, authenticate: authenticate).value
                return try JSONDecoder().decode(Response.self, from: responseData)
            } catch {
                debugPrint(error)
                throw error
            }
        }
    }

    private func load(request: URLRequest, authenticate: Bool) async throws -> Task<Data, Swift.Error> {
        Task {
            debugPrint("Loading request with url: \(request.url!.absoluteString)") // TODO: Remove when logger in place
            var request = request
            if authenticate, let token = dependencies.authenticator.token {
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw Error.invalidResponse
            }
            guard 200..<400 ~= httpResponse.statusCode else {
                throw Error.httpError(httpResponse.statusCode)
            }
            return data
        }
    }
}
