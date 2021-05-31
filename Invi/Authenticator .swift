//
//  Authenticator .swift
//  Invi
//
//  Created by Michal Gorzalczany on 30/05/2021.
//

import Foundation

protocol AuthenticatorType {
    var isLoggedIn: Bool { get }
}

final class Authenticator: AuthenticatorType {
    var isLoggedIn: Bool { false }
}
