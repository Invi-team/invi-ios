//
//  AuthenticatedSessionTests.swift
//  
//
//  Created by Marcin Mucha on 16/06/2022.
//

import Foundation
import XCTest
@testable import InviAuthenticator
import WebService
import WebServiceTestHelpers

final class AuthenticatedSessionTests: XCTestCase {
    func testData_whenSuccessfulResponse_shouldSucceed() async throws {
        // Arrange
        let configuration = Authenticator.Configuration.prod
        let fakeData = "fake".data(using: .utf8)!
        let endpointURL = URL(string: "https://invi.click/api/v1/fakePrivateEndpoint")!
        var numberOfTimesCalled = 0
        let fakeWebService = WebService {
            numberOfTimesCalled += 1
            return [endpointURL: .success(fakeData)]
        }
        let fakeTokens = UserTokens(accessToken: "accessToken", refreshToken: "refreshToken")
        let fakeTokenController = FakeTokenController(userTokens: fakeTokens)
        let sut = AuthenticatedSession(tokenController: fakeTokenController, webService: fakeWebService, configuration: configuration)
        
        // Act
        let (data, response) = try await sut.data(for: URLRequest(url: endpointURL))
        
        // Assert
        XCTAssertEqual(data, fakeData)
        XCTAssertEqual(response.statusCode, 200)
        let tokens = await fakeTokenController.userTokens
        XCTAssertEqual(tokens, fakeTokens)
        XCTAssertEqual(numberOfTimesCalled, 1)
    }
    
    func testData_whenFailedNon401Response_shouldFail() async throws {
        // Arrange
        let configuration = Authenticator.Configuration.prod
        let endpointURL = URL(string: "https://prod.invi.click/api/v1/fakePrivateEndpoint")!
        var numberOfTimesCalled = 0
        let fakeWebService = WebService {
            numberOfTimesCalled += 1
            return [endpointURL: .failure(503)]
        }
        let fakeTokens = UserTokens(accessToken: "accessToken", refreshToken: "refreshToken")
        let fakeTokenController = FakeTokenController(userTokens: fakeTokens)
        let sut = AuthenticatedSession(tokenController: fakeTokenController, webService: fakeWebService, configuration: configuration)
        // Act
        let (_, response) = try await sut.data(for: URLRequest(url: endpointURL))
        
        // Assert
        XCTAssertEqual(response.statusCode, 503)
        let tokens = await fakeTokenController.userTokens
        XCTAssertEqual(tokens, fakeTokens)
        XCTAssertEqual(numberOfTimesCalled, 1)
    }
    
    func testData_whenFailed401ResponseAndSuccessfulRefresh_shouldSucceed() async throws {
        // Arrange
        let configuration = Authenticator.Configuration.prod
        let endpointURL = URL(string: "https://prod.invi.click/api/v1/fakePrivateEndpoint")!
        let refreshTokenURL = URL(string: "https://prod.invi.click/api/v1/auth/refresh-session")!
        
        let newTokens = UserTokens(accessToken: "newAccessToken", refreshToken: "newRefreshToken")
        let newTokensData = try JSONEncoder().encode(newTokens)
        let fakeTokenController = FakeTokenController(userTokens: UserTokens(accessToken: "oldAccessToken", refreshToken: "oldRefreshToken"))
        
        let fakeSuccessData = "fakeSuccess".data(using: .utf8)!
        
        var numberOfTimesCalled = 0
        let fakeWebService = WebService {
            numberOfTimesCalled += 1
            return [
                endpointURL: numberOfTimesCalled == 1 ? .failure(401) : .success(fakeSuccessData),
                refreshTokenURL: .success(newTokensData)
            ]
        }
        let sut = AuthenticatedSession(tokenController: fakeTokenController, webService: fakeWebService, configuration: configuration)
        // Act
        let (data, response) = try await sut.data(for: URLRequest(url: endpointURL))
        
        // Assert
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(data, fakeSuccessData)
        XCTAssertEqual(numberOfTimesCalled, 3)
        let tokens = await fakeTokenController.userTokens
        XCTAssertEqual(tokens, newTokens)
    }
    
    func testData_whenFailed401ResponseAndSuccessfulRefresh_shouldFail() async throws {
        // Arrange
        let configuration = Authenticator.Configuration.prod
        let endpointURL = URL(string: "https://prod.invi.click/api/v1/fakePrivateEndpoint")!
        let refreshTokenURL = URL(string: "https://prod.invi.click/api/v1/auth/refresh-session")!
        
        let newTokens = UserTokens(accessToken: "newAccessToken", refreshToken: "newRefreshToken")
        let newTokensData = try JSONEncoder().encode(newTokens)
        let fakeTokenController = FakeTokenController(userTokens: UserTokens(accessToken: "oldAccessToken", refreshToken: "oldRefreshToken"))
        
        var numberOfTimesCalled = 0
        let fakeWebService = WebService {
            numberOfTimesCalled += 1
            return [
                endpointURL: numberOfTimesCalled == 1 ? .failure(401) : .failure(503),
                refreshTokenURL: .success(newTokensData)
            ]
        }
        let sut = AuthenticatedSession(tokenController: fakeTokenController, webService: fakeWebService, configuration: configuration)
        // Act
        let (_, response) = try await sut.data(for: URLRequest(url: endpointURL))
        
        // Assert
        XCTAssertEqual(response.statusCode, 503)
        XCTAssertEqual(numberOfTimesCalled, 3)
        let tokens = await fakeTokenController.userTokens
        XCTAssertEqual(tokens, newTokens)
    }
    
    func testData_whenFailed401ResponseAndFailedRefresh_shouldFail() async throws {
        // Arrange
        let configuration = Authenticator.Configuration.prod
        let endpointURL = URL(string: "https://prod.invi.click/api/v1/fakePrivateEndpoint")!
        let refreshTokenURL = URL(string: "https://prod.invi.click/api/v1/auth/refresh-session")!
        
        let oldTokens = UserTokens(accessToken: "oldAccessToken", refreshToken: "oldRefreshToken")
        let fakeTokenController = FakeTokenController(userTokens: oldTokens)
        
        let fakeSuccessData = "fakeSuccess".data(using: .utf8)!
        
        var numberOfTimesCalled = 0
        let fakeWebService = WebService {
            numberOfTimesCalled += 1
            return [
                endpointURL: numberOfTimesCalled == 1 ? .failure(401) : .success(fakeSuccessData),
                refreshTokenURL: .failure(503)
            ]
        }
        let sut = AuthenticatedSession(tokenController: fakeTokenController, webService: fakeWebService, configuration: configuration)
        // Act
        let (_, response) = try await sut.data(for: URLRequest(url: endpointURL))
        
        // Assert
        XCTAssertEqual(response.statusCode, 401)
        XCTAssertEqual(numberOfTimesCalled, 2)
        let tokens = await fakeTokenController.userTokens
        XCTAssertEqual(tokens, oldTokens)
    }
}

private actor FakeTokenController: TokenControllerType {
    private(set) var userTokens: UserTokens
    
    init(userTokens: UserTokens) {
        self.userTokens = userTokens
    }
    
    func set(tokens: UserTokens) {
        userTokens = tokens
    }
    
    
}
