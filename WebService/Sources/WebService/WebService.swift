//
//  WebService.swift
//  WebService
//
//  Created by Marcin Mucha on 20/05/2021.
//

import Foundation

public protocol WebServiceType {
    func get<T: Decodable>(request: URLRequest) -> Task<T, Swift.Error>
    func post<Model: Encodable, Response: Decodable>(model: Model, request: URLRequest) -> Task<Response, Swift.Error>
    func put<Model: Encodable, Response: Decodable>(model: Model, request: URLRequest) -> Task<Response, Swift.Error>

    // TODO: Remove when API stop returning empty response
    func put<Model: Encodable>(model: Model, request: URLRequest) -> Task<Void, Swift.Error>
    func post<Model: Encodable>(model: Model?, request: URLRequest) -> Task<Void, Swift.Error>
}

public protocol URLSessionType {
    func data(for request: URLRequest, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionType {}

public final class WebService: WebServiceType {
    private let session: URLSessionType
    private let userToken: () -> String?
    private let decoder: JSONDecoder

    public init(
        session: URLSessionType = URLSession.shared,
        decoder: JSONDecoder = JSONDecoder(),
        userToken: @escaping () -> String? = { nil }) {
        self.session = session
        self.decoder = decoder
        self.userToken = userToken
    }

    public enum Error: Equatable, Swift.Error {
        case invalidResponse
        case httpError(Int, message: String, metadata: [String])
    }

    public func get<T: Decodable>(request: URLRequest) -> Task<T, Swift.Error> {
        Task {
            switch await load(request: request).result {
            case .success(let data):
                return try decoder.decode(T.self, from: data)
            case .failure(let error):
                debugPrint(error)
                throw error
            }
        }
    }

    public func post<Model: Encodable, Response: Decodable>(model: Model, request: URLRequest) -> Task<Response, Swift.Error> {
        putOrPost(method: .post, model: model, request: request)
    }

    public func put<Model: Encodable, Response: Decodable>(model: Model, request: URLRequest) -> Task<Response, Swift.Error> {
        putOrPost(method: .put, model: model, request: request)
    }

    public func put<Model: Encodable>(model: Model, request: URLRequest) -> Task<Void, Swift.Error> {
        Task {
            let data = try JSONEncoder().encode(model)
            var request = request
            request.httpMethod = "PUT"
            request.httpBody = data

            switch await load(request: request).result {
            case .success:
                debugPrint("Success")
                return ()
            case .failure(let error):
                debugPrint("Failure \(error)")
                throw error
            }
        }
    }

    public func post<Model: Encodable>(model: Model?, request: URLRequest) -> Task<Void, Swift.Error> {
        Task {
            let data = try model.flatMap { try JSONEncoder().encode($0) }
            var request = request
            request.httpMethod = "POST"
            data.flatMap { request.httpBody = $0 }

            switch await load(request: request).result {
            case .success:
                debugPrint("Success")
                return ()
            case .failure(let error):
                debugPrint("Failure \(error)")
                throw error
            }
        }
    }

    private enum PostOrPut: String {
        case post = "POST", put = "PUT"
    }

    private func putOrPost<Model: Encodable, Response: Decodable>(method: PostOrPut, model: Model, request: URLRequest) -> Task<Response, Swift.Error> {
        Task {
            let data = try JSONEncoder().encode(model)
            var request = request
            request.httpMethod = method.rawValue
            request.httpBody = data
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")

            switch await load(request: request).result {
            case .success(let responseData):
                return try decoder.decode(Response.self, from: responseData)
            case .failure(let error):
                debugPrint(error)
                throw error
            }
        }
    }

    private struct ErrorResponse: Decodable {
        let code: Int
        let message: String?
        let metadata: [String]?
    }

    private func load(request: URLRequest) -> Task<Data, Swift.Error> {
        Task {
            try Task.checkCancellation()
            debugPrint("Loading request with url: \(request.url!.absoluteString)") // TODO: Remove when logger in place
            var request = request
            if let token = userToken() {
                request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            let (data, response) = try await session.data(for: request, delegate: nil)
            try Task.checkCancellation()
            guard let httpResponse = response as? HTTPURLResponse else {
                throw Error.invalidResponse
            }
            guard 200..<400 ~= httpResponse.statusCode else {
                let errorResponse = try? decoder.decode(ErrorResponse.self, from: data)
                let metadata = errorResponse?.metadata ?? []
                let message = errorResponse?.message ?? ""
                throw Error.httpError(httpResponse.statusCode, message: message, metadata: metadata)
            }
            return data
        }
    }
}
