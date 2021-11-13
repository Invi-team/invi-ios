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
        let model: FakeModel = try await webService.get(request: URLRequest(url: url)).value

        // Assert
        XCTAssertEqual(model, FakeModel(name: "Jan", age: 24, car: nil))
    }

    func testGet_whenFail() async throws {
        // Arrange
        let url = URL(string: "www.example.com")!
        let webService = WebService(results: [url: .failure(503)])

        // Act
        let result: Result<FakeModel, Error> = try await webService.get(request: URLRequest(url: url)).result

        // Assert
        let error = result.error as! WebService.Error
        XCTAssertEqual(error, WebService.Error.httpError(503))
    }
}
