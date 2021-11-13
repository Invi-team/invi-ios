//
//  WebService.swift
//  WebService
//
//  Created by Marcin Mucha on 20/05/2021.
//

import Foundation

public protocol WebServiceType {
    func get<T: Decodable>(request: URLRequest) async throws -> Task<T, Swift.Error>
    func post<Model: Encodable, Response: Decodable>(model: Model, request: URLRequest) async throws -> Task<Response, Swift.Error>
    func put<Model: Encodable, Response: Decodable>(model: Model, request: URLRequest) async throws -> Task<Response, Swift.Error>

    // TODO: Remove when API stop returning empty response
    func put<Model: Encodable>(model: Model, request: URLRequest) async throws -> Task<Void, Swift.Error>
}

public protocol URLSessionType {
    func data(for request: URLRequest, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionType {}

public final class WebService: WebServiceType {
    private let session: URLSessionType
    private let userToken: () -> String?

    public init(session: URLSessionType = URLSession.shared, userToken: @escaping () -> String? = { nil }) {
        self.session = session
        self.userToken = userToken
    }

    public enum Error: Equatable, Swift.Error {
        case invalidResponse
        case httpError(Int)
    }

    public func get<T: Decodable>(request: URLRequest) async throws -> Task<T, Swift.Error> {
        Task {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let data: Data
            do {
                data = try await load(request: request).value
                return try decoder.decode(T.self, from: data)
            } catch {
                debugPrint(error)
                throw error
            }
        }
    }

    public func post<Model: Encodable, Response: Decodable>(model: Model, request: URLRequest) async throws -> Task<Response, Swift.Error> {
        try await putOrPost(method: .post, model: model, request: request)
    }

    public func put<Model: Encodable, Response: Decodable>(model: Model, request: URLRequest) async throws -> Task<Response, Swift.Error> {
        try await putOrPost(method: .put, model: model, request: request)
    }

    public func put<Model: Encodable>(model: Model, request: URLRequest) async throws -> Task<Void, Swift.Error> {
        Task {
            let data = try JSONEncoder().encode(model)
            var request = request
            request.httpMethod = "PUT"
            request.httpBody = data

            do {
                _ = try await load(request: request)
            } catch {
                debugPrint(error)
                throw error
            }
        }
    }

    private enum PostOrPut: String {
        case post = "POST", put = "PUT"
    }

    private func putOrPost<Model: Encodable, Response: Decodable>(method: PostOrPut, model: Model, request: URLRequest) async throws -> Task<Response, Swift.Error> {
        Task {
            let data = try JSONEncoder().encode(model)
            var request = request
            request.httpMethod = method.rawValue
            request.httpBody = data

            let responseData: Data
            do {
                responseData = try await load(request: request).value
                return try JSONDecoder().decode(Response.self, from: responseData)
            } catch {
                debugPrint(error)
                throw error
            }
        }
    }

    private func load(request: URLRequest) async throws -> Task<Data, Swift.Error> {
        Task {
            debugPrint("Loading request with url: \(request.url!.absoluteString)") // TODO: Remove when logger in place
            var request = request
            if let token = userToken() {
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            let (data, response) = try await session.data(for: request, delegate: nil)
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
