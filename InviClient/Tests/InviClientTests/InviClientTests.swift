import XCTest
@testable import InviClient
import WebService
import WebServiceTestHelpers
import TestHelpers

final class InviClientTests: XCTestCase {
    func testInvitations_whenSuccess() async throws {
        // Arrange
        let environment: ApiEnvironment = .prod
        let url = URL(string: "\(environment.baseURL)")!.appendingPathComponent("invitations")
        let data = try Bundle.module.readLocalFile(forName: "Invitations")
        let webService = WebService(results: [url: .success(data)], decoder: JSONDecoder.inviDecoder)
        let client: InviClient = .live(environment: environment, webService: webService)

        // Act
        let invitations = try await client.invitations()

        // Assert
        XCTAssertEqual(invitations.count, 3)
        XCTAssertEqual(invitations[0].id, "c78ce6ef-7fe9-4e33-b107-811de79c8889")
    }

    func testInvitations_whenFail() async throws {
        // Arrange
        let environment: ApiEnvironment = .prod
        let url = URL(string: "\(environment.baseURL)")!.appendingPathComponent("invitations")
        let webService = WebService(results: [url: .failure(503)], decoder: JSONDecoder.inviDecoder)
        let client: InviClient = .live(environment: environment, webService: webService)

        // Act
        do {
            _ = try await client.invitations()
            XCTFail()
        } catch {
            let error = error as! WebService.Error
            XCTAssertEqual(error, WebService.Error.httpError(503, message: "", metadata: []))
        }
    }
}
