//
//  WebService.swift
//  WebService
//
//  Created by Marcin Mucha on 20/05/2021.
//

import Foundation

public protocol WebServiceType {
    func get<T: Decodable>(request: URLRequest, customSession: URLSessionType?) async throws -> T
    func post<Model: Encodable, Response: Decodable>(model: Model, request: URLRequest, customSession: URLSessionType?) async throws -> Response
    func put<Model: Encodable, Response: Decodable>(model: Model, request: URLRequest, customSession: URLSessionType?) async throws -> Response

    // TODO: Remove when API stop returning empty response
    func put<Model: Encodable>(model: Model, request: URLRequest, customSession: URLSessionType?) async throws
    func post<Model: Encodable>(model: Model?, request: URLRequest, customSession: URLSessionType?) async throws
    func data(for request: URLRequest, delegate: URLSessionTaskDelegate?, customSession: URLSessionType?) async throws -> (Data, URLResponse)
}

public extension WebServiceType {
    func get<T: Decodable>(request: URLRequest) async throws -> T {
        try await get(request: request, customSession: nil)
    }
    
    func post<Model: Encodable, Response: Decodable>(model: Model, request: URLRequest) async throws -> Response {
        try await post(model: model, request: request, customSession: nil)
    }
    func put<Model: Encodable, Response: Decodable>(model: Model, request: URLRequest) async throws -> Response {
        try await put(model: model, request: request, customSession: nil)
    }

    // TODO: Remove when API stop returning empty response
    func put<Model: Encodable>(model: Model, request: URLRequest) async throws {
        try await put(model: model, request: request, customSession: nil)
        
    }
    func post<Model: Encodable>(model: Model?, request: URLRequest) async throws {
        try await post(model: model, request: request, customSession: nil)
    }
    
    func data(for request: URLRequest, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse) {
        try await data(for: request, delegate: delegate, customSession: nil)
    }
}

public protocol URLSessionType {
    func data(for request: URLRequest, delegate: URLSessionTaskDelegate?) async throws -> (Data, URLResponse)
}

extension URLSession: URLSessionType {}

public final class WebService: WebServiceType {
    private let session: URLSessionType
    private let decoder: JSONDecoder

    public init(
        session: URLSessionType = URLSession.shared,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.session = session
        self.decoder = decoder
    }

    public enum Error: Equatable, Swift.Error {
        case invalidResponse
        case httpError(Int, message: String, metadata: [String])
    }

    public func get<T: Decodable>(request: URLRequest, customSession: URLSessionType? = nil) async throws -> T {
        do {
            let data = try await load(request: request, customSession: customSession)
            return try decoder.decode(T.self, from: data)
        } catch {
            debugPrint(error)
            throw error
        }
    }

    public func post<Model: Encodable, Response: Decodable>(model: Model, request: URLRequest, customSession: URLSessionType? = nil) async throws -> Response {
        try await putOrPost(method: .post, model: model, request: request, customSession: customSession)
    }

    public func put<Model: Encodable, Response: Decodable>(model: Model, request: URLRequest, customSession: URLSessionType? = nil) async throws -> Response {
        try await putOrPost(method: .put, model: model, request: request, customSession: customSession)
    }

    public func put<Model: Encodable>(model: Model, request: URLRequest, customSession: URLSessionType? = nil) async throws {
        let data = try JSONEncoder().encode(model)
        var request = request
        request.httpMethod = "PUT"
        request.httpBody = data
        
        _ = try await load(request: request, customSession: customSession)
    }

    public func post<Model: Encodable>(model: Model?, request: URLRequest, customSession: URLSessionType? = nil) async throws {
        let data = try model.flatMap { try JSONEncoder().encode($0) }
        var request = request
        request.httpMethod = "POST"
        data.flatMap { request.httpBody = $0 }
        
        _ = try await load(request: request, customSession: customSession)
    }
    
    public func data(for request: URLRequest, delegate: URLSessionTaskDelegate?, customSession: URLSessionType? = nil) async throws -> (Data, URLResponse) {
        try await session.data(for: request, delegate: delegate)
    }

    private enum PostOrPut: String {
        case post = "POST", put = "PUT"
    }

    private func putOrPost<Model: Encodable, Response: Decodable>(method: PostOrPut, model: Model, request: URLRequest, customSession: URLSessionType? = nil) async throws -> Response {
        let data = try JSONEncoder().encode(model)
        var request = request
        request.httpMethod = method.rawValue
        request.httpBody = data
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let responseData = try await load(request: request, customSession: customSession)
        return try decoder.decode(Response.self, from: responseData)
    }

    public struct ErrorResponse: Codable {
        let code: Int
        let message: String?
        let metadata: [String]?
        
        public init(code: Int, message: String?, metadata: [String]?) {
            self.code = code
            self.message = message
            self.metadata = metadata
        }
    }

    private func load(request: URLRequest, customSession: URLSessionType?) async throws -> Data {
        debugPrint("Loading request with url: \(request.url!.absoluteString)") // TODO: Remove when logger in place
        let (data, response) = try await (customSession ?? session).data(for: request, delegate: nil)
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
