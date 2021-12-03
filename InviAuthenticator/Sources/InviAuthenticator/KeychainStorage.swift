//
//  KeychainStorage.swift
//  
//
//  Created by Marcin Mucha on 13/11/2021.
//

import Foundation
import Security

protocol KeychainStorageType {
    func add(token: String) throws
    func getToken() throws -> String
    func removeToken() throws
}

struct KeychainStorage: KeychainStorageType {
    enum Error: Swift.Error {
        case addingTokenFailed
        case readingTokenFailed
        case removingTokenFailed
    }

    private let tag = "com.invi.accessToken".data(using: .utf8)!

    func add(token: String) throws {
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrApplicationTag as String: tag,
            kSecValueData as String: token.data(using: .utf8)!
        ]
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        guard status == errSecSuccess else { throw Error.addingTokenFailed }
    }

    func getToken() throws -> String {
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

    func removeToken() throws {
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
