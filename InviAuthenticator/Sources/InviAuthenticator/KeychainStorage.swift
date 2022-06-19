//
//  KeychainStorage.swift
//  
//
//  Created by Marcin Mucha on 13/11/2021.
//

import Foundation
import Security

protocol KeychainStorageType {
    func add(tokens: UserTokens) throws
    func getTokens() throws -> UserTokens
    func removeTokens() throws
}

struct KeychainStorage: KeychainStorageType {
    enum Error: Swift.Error {
        case addingTokenFailed
        case readingTokenFailed
        case removingTokenFailed
    }

    private let accessTokenTag = "com.invi.accessToken".data(using: .utf8)!
    private let refreshTokenTag = "com.invi.refreshToken".data(using: .utf8)!
    
    func add(tokens: UserTokens) throws {
        try add(token: tokens.refreshToken, tag: refreshTokenTag)
        try add(token: tokens.accessToken, tag: accessTokenTag)
    }
    
    func getTokens() throws -> UserTokens {
        let refreshToken = try getToken(tag: refreshTokenTag)
        let accessToken = try getToken(tag: accessTokenTag)
        return UserTokens(accessToken: accessToken, refreshToken: refreshToken)
    }
    
    func removeTokens() throws {
        try removeToken(tag: refreshTokenTag)
        try removeToken(tag: accessTokenTag)
    }

    private func add(token: String, tag: Data) throws {
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tag,
            kSecValueData as String: token.data(using: .utf8)!
        ]
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else { throw Error.addingTokenFailed }
    }

    func getToken(tag: Data) throws -> String {
        let getQuery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tag,
            kSecReturnData as String: true
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(getQuery as CFDictionary, &item)
        guard status == errSecSuccess else { throw Error.readingTokenFailed }
        if let data = item as? Data {
            return String(decoding: data, as: UTF8.self)
        } else {
            throw Error.readingTokenFailed
        }
    }

    func removeToken(tag: Data) throws {
        let removeQuery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tag,
            kSecReturnData as String: true
        ]
        let status = SecItemDelete(removeQuery as CFDictionary)
        guard status == errSecSuccess || status == status else {
            throw Error.removingTokenFailed
        }
    }
}
