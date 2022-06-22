//
//  FakeWebService.swift
//  
//
//  Created by Marcin Mucha on 13/11/2021.
//

import Foundation
import WebService

public enum FakeResult {
    case success(Data)
    case failure(statusCode: Int, metadata: [String])
    
    public static func failure(_ code: Int) -> FakeResult {
        .failure(statusCode: code, metadata: [])
    }
}

extension WebService {
    public convenience init(results: [URL: FakeResult], decoder: JSONDecoder = JSONDecoder()) {
        self.init(session: FakeURLSession(results: { results }), decoder: decoder)
    }
    
    public convenience init(results: @escaping () -> [URL: FakeResult], decoder: JSONDecoder = JSONDecoder()) {
        self.init(session: FakeURLSession(results: results), decoder: decoder)
    }
}

private class FakeURLSession: URLSessionType {
    let results: () -> [URL: FakeResult]

    init(results: @escaping () -> [URL: FakeResult]) {
        self.results = results
    }

    func data(for request: URLRequest, delegate: URLSessionTaskDelegate? = nil) async throws -> (Data, URLResponse) {
        let url = request.url!
        switch results()[url] {
        case .some(.success(let data)):
            return (data, HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: request.allHTTPHeaderFields)!)
        case .some(.failure(let statusCode, let metadata)):
            let errorModel = WebService.ErrorResponse(code: statusCode, message: "", metadata: metadata)
            let errorData = try JSONEncoder().encode(errorModel)
            return (errorData, HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: request.allHTTPHeaderFields)!)
        case .none:
            fatalError("Result not defined for a given url. ")
        }
    }
}
