//
//  FakeUserDefaults.swift
//  
//
//  Created by Marcin Mucha on 05/12/2021.
//

import Foundation
import XCTest
@testable import Invi

public final class FakeUserDefaults: UserDefaultsType {
    private var userDefaults = [String: Any]()

    public init() {}

    public func double(forKey key: UserDefaultName) -> Double? {
        return userDefaults[key.rawValue] as? Double
    }

    public func set(double: Double, forKey key: UserDefaultName) {
        userDefaults[key.rawValue] = double
    }

    public func int(forKey key: UserDefaultName) -> Int? {
        return userDefaults[key.rawValue] as? Int
    }

    public func set(int: Int, forKey key: UserDefaultName) {
        userDefaults[key.rawValue] = int
    }

    public func removeValue(forKey key: UserDefaultName) {
        userDefaults.removeValue(forKey: key.rawValue)
    }

    public func bool(forKey defaultName: UserDefaultName) -> Bool? {
        return userDefaults[defaultName.rawValue] as? Bool
    }

    public func set(bool: Bool, forKey defaultName: UserDefaultName) {
        userDefaults[defaultName.rawValue] = bool
    }

    public func string(forKey defaultName: UserDefaultName) -> String? {
        return userDefaults[defaultName.rawValue] as? String
    }

    public func set(string: String, forKey defaultName: UserDefaultName) {
        userDefaults[defaultName.rawValue] = string
    }

    public func date(forKey defaultName: UserDefaultName) -> Date? {
        return userDefaults[defaultName.rawValue] as? Date
    }

    public func set(date: Date, forKey defaultName: UserDefaultName) {
        userDefaults[defaultName.rawValue] = date
    }

    public func data(forKey defaultName: UserDefaultName) -> Data? {
        return userDefaults[defaultName.rawValue] as? Data
    }

    public func set(data: Data, forKey defaultName: UserDefaultName) {
        userDefaults[defaultName.rawValue] = data
    }

    public func dictionary(forKey defaultName: UserDefaultName) -> [String: Any]? {
        return userDefaults[defaultName.rawValue] as? [String: Any]
    }

    public func set(dictionary: [String: Any], forKey defaultName: UserDefaultName) {
        userDefaults[defaultName.rawValue] = dictionary
    }
}
