//
//  Mocks.swift
//  
//
//  Created by Marcin Mucha on 13/11/2021.
//

import Foundation

extension Authenticator {
    public static var loggedIn: Authenticator {
        let state = State.loggedIn(token: "fakeToken", user: User(id: "123-abc", email: "marcin@invi.click", name: "Marcin", surname: "Nowak"))

        return Authenticator(
            state: .init(state),
            login: { _, _ in fatalError()},
            register: { _, _ in fatalError() },
            logout: {}
        )
    }
}
