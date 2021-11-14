//
//  Result+Extensions.swift
//  
//
//  Created by Marcin Mucha on 13/11/2021.
//

import Foundation
import XCTest

extension Result {
    public var error: Error {
        guard case .failure(let error) = self else {
            fatalError("The result is not a failure.")
        }
        return error
    }
}
