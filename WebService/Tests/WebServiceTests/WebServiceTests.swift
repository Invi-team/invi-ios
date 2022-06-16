import XCTest
@testable import WebService
import WebServiceTestHelpers
import TestHelpers

final class WebServiceTests: XCTestCase {
    struct FakeModel: Equatable, Codable {
        let name: String
        let age: Int
        let car: String?
    }

    let fakeModelData = """
        {
            "name": "Jan",
            "age": 24,
            "car": null
        }
    """.data(using: .utf8)!

    func testGet_whenSuccess() async throws {
        // Arrange
        let url = URL(string: "www.example.com")!
        let webService = WebService(results: [url: .success(fakeModelData)])

        // Act
        let model: FakeModel = try await webService.get(request: URLRequest(url: url))

        // Assert
        XCTAssertEqual(model, FakeModel(name: "Jan", age: 24, car: nil))
    }

    func testGet_whenFail() async throws {
        // Arrange
        let url = URL(string: "www.example.com")!
        let webService = WebService(results: [url: .failure(503)])

        // Act
        let result: Result<FakeModel, Error> = await Task {
            try await webService.get(request: URLRequest(url: url))
        }.result

        // Assert
        let error = result.error as! WebService.Error
        XCTAssertEqual(error, WebService.Error.httpError(503, message: "", metadata: []))
    }

    func testPostWithResponse_whenSuccess() async throws {
        // Arrange
        let url = URL(string: "www.example.com")!
        let webService = WebService(results: [url: .success(fakeModelData)])
        let model = FakeModel(name: "Fake", age: 20, car: nil)

        // Act
        let responseModel: FakeModel = try await webService.post(model: model, request: URLRequest(url: url))

        // Assert
        XCTAssertEqual(responseModel, FakeModel(name: "Jan", age: 24, car: nil))
    }

    func testPostWithResponse_whenFail() async throws {
        // Arrange
        let url = URL(string: "www.example.com")!
        let webService = WebService(results: [url: .failure(404)])
        let model = FakeModel(name: "Fake", age: 20, car: nil)

        // Act
        let result: Result<FakeModel, Error> = await Task {
            try await webService.post(model: model, request: URLRequest(url: url))
        }.result

        // Assert
        let error = result.error as! WebService.Error
        XCTAssertEqual(error, WebService.Error.httpError(404, message: "", metadata: []))
    }

    func testPostWithEmptyResponse_whenSuccess() async throws {
        // Arrange
        let url = URL(string: "www.example.com")!
        let webService = WebService(results: [url: .success(fakeModelData)])

        // Act & Assert
        _ = try await webService.post(model: FakeModel?.none, request: URLRequest(url: url))
    }

    func testPostWithEmptyResponse_whenFail() async throws {
        // Arrange
        let url = URL(string: "www.example.com")!
        let webService = WebService(results: [url: .failure(404)])

        // Act
        let result: Result<FakeModel, Error> = await Task {
            try await webService.post(model: FakeModel?.none, request: URLRequest(url: url))
        }.result

        // Assert
        let error = result.error as! WebService.Error
        XCTAssertEqual(error, WebService.Error.httpError(404, message: "", metadata: []))
    }

    func testPutWithResponse_whenSuccess() async throws {
        // Arrange
        let url = URL(string: "www.example.com")!
        let webService = WebService(results: [url: .success(fakeModelData)])
        let model = FakeModel(name: "Fake", age: 20, car: nil)

        // Act
        let responseModel: FakeModel = try await webService.put(model: model, request: URLRequest(url: url))

        // Assert
        XCTAssertEqual(responseModel, FakeModel(name: "Jan", age: 24, car: nil))
    }

    func testPutWithResponse_whenFail() async throws {
        // Arrange
        let url = URL(string: "www.example.com")!
        let webService = WebService(results: [url: .failure(404)])
        let model = FakeModel(name: "Fake", age: 20, car: nil)

        // Act
        let result: Result<FakeModel, Error> = await Task {
            try await webService.put(model: model, request: URLRequest(url: url))
        }.result

        // Assert
        let error = result.error as! WebService.Error
        XCTAssertEqual(error, WebService.Error.httpError(404, message: "", metadata: []))
    }

    func testPutWithEmptyResponse_whenSuccess() async throws {
        // Arrange
        let url = URL(string: "www.example.com")!
        let webService = WebService(results: [url: .success(fakeModelData)])

        // Act & Assert
        try await webService.put(model: FakeModel?.none, request: URLRequest(url: url))
    }

    func testPutWithEmptyResponse_whenFail() async throws {
        // Arrange
        let url = URL(string: "www.example.com")!
        let webService = WebService(results: [url: .failure(404)])

        // Act
        let result: Result<FakeModel, Error> = await Task {
            try await webService.put(model: FakeModel?.none, request: URLRequest(url: url))
        }.result

        // Assert
        let error = result.error as! WebService.Error
        XCTAssertEqual(error, WebService.Error.httpError(404, message: "", metadata: []))
    }
}
