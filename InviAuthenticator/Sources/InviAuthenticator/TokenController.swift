//
//  TokenController.swift
//  
//
//  Created by Marcin Mucha on 19/06/2022.
//

import Foundation

protocol TokenControllerType: Actor {
    var userTokens: UserTokens { get }
    func set(tokens: UserTokens)
}

public actor TokenController: TokenControllerType {
    public private(set) var userTokens: UserTokens {
        didSet {
            guard userTokens != oldValue else { return }
            Self.save(userTokens: userTokens, keychainStorage: keychainStorage)
        }
    }
    
    private let keychainStorage: KeychainStorageType
    
    init?(keychainStorage: KeychainStorageType) {
        self.keychainStorage = keychainStorage
        
        do {
            self.userTokens = try keychainStorage.getTokens()
        } catch {
            return nil
        }
    }
    
    init(userTokens: UserTokens, keychainStorage: KeychainStorageType) {
        self.userTokens = userTokens
        self.keychainStorage = keychainStorage
        
        Self.save(userTokens: userTokens, keychainStorage: keychainStorage)
    }
    
    deinit {
        do {
            try keychainStorage.removeTokens()
            debugPrint("Successfully removed tokens from keychain")
        } catch {
            debugPrint("Failed to remove tokens from keychain when deiniting TokenController")
        }
    }
    
    func set(tokens: UserTokens) {
        userTokens = tokens
    }
    
    // static method in order to avoid `self` usage in init which leads to warning about async init required in Swift 6
    private static func save(userTokens: UserTokens, keychainStorage: KeychainStorageType) {
        do {
            try keychainStorage.removeTokens()
            try keychainStorage.add(tokens: userTokens)
            debugPrint("Successfully added new tokens to keychain.")
        } catch {
            debugPrint("Failed adding new tokens to keychain.")
        }
    }
}
