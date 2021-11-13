//
//  File.swift
//  
//
//  Created by Marcin Mucha on 13/11/2021.
//

import Foundation

extension Authenticator {
    public static let loggedIn = Authenticator(state: .init(.loggedIn(token: "fakeToken")), login: { _, _ in fatalError() }, register: { _, _ in fatalError() }, logout: {})
}
