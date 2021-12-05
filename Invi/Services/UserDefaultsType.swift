//
//  UserDefaults.swift
//  Invi
//
//  Created by Marcin Mucha on 05/12/2021.
//

import Foundation

protocol UserDefaultsType: AnyObject {
    func bool(forKey: UserDefaultName) -> Bool?
    func set(bool: Bool, forKey: UserDefaultName)

    func string(forKey: UserDefaultName) -> String?
    func set(string: String, forKey: UserDefaultName)

    func int(forKey: UserDefaultName) -> Int?
    func set(int: Int, forKey: UserDefaultName)

    func double(forKey: UserDefaultName) -> Double?
    func set(double: Double, forKey: UserDefaultName)

    func date(forKey: UserDefaultName) -> Date?
    func set(date: Date, forKey: UserDefaultName)

    func removeValue(forKey: UserDefaultName)

    func data(forKey: UserDefaultName) -> Data?
    func set(data: Data, forKey: UserDefaultName)

    func dictionary(forKey defaultName: UserDefaultName) -> [String: Any]?
    func set(dictionary: [String: Any], forKey defaultName: UserDefaultName)
}

extension UserDefaultsType {
    func set<T>(codable: T, forKey key: UserDefaultName) throws where T: Decodable, T: Encodable {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(codable)
        set(data: data, forKey: key)
    }

    func codable<T>(forKey key: UserDefaultName) -> T? where T: Decodable, T: Encodable {
        guard let data = data(forKey: key) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(T.self, from: data)
    }
}

extension UserDefaults: UserDefaultsType {
    func removeValue(forKey defaultName: UserDefaultName) {
        removeObject(forKey: defaultName.rawValue)
    }

    func int(forKey defaultName: UserDefaultName) -> Int? {
        return object(forKey: defaultName)
    }

    func set(int value: Int, forKey key: UserDefaultName) {
        set(value, forKey: key.rawValue)
    }

    func double(forKey defaultName: UserDefaultName) -> Double? {
        return object(forKey: defaultName)
    }

    func set(double value: Double, forKey key: UserDefaultName) {
        set(value, forKey: key.rawValue)
    }

    private func object<T>(forKey defaultName: UserDefaultName) -> T? {
        return object(forKey: defaultName.rawValue) as? T
    }

    func bool(forKey defaultName: UserDefaultName) -> Bool? {
        let value: NSNumber? = object(forKey: defaultName)
        return value?.boolValue
    }

    func set(bool value: Bool, forKey defaultName: UserDefaultName) {
        set(value, forKey: defaultName.rawValue)
    }

    func string(forKey defaultName: UserDefaultName) -> String? {
        let string: String? = object(forKey: defaultName)
        return string
    }

    func set(string value: String, forKey defaultName: UserDefaultName) {
        set(value, forKey: defaultName.rawValue)
    }

    // MARK: - Date

    func date(forKey defaultName: UserDefaultName) -> Date? {
        let date: NSDate? = object(forKey: defaultName)
        return date as Date?
    }

    func set(date value: Date, forKey defaultName: UserDefaultName) {
        set(value as NSDate, forKey: defaultName.rawValue)
    }

    func data(forKey defaultName: UserDefaultName) -> Data? {
        let data: Data? = object(forKey: defaultName)
        return data
    }

    func set(data: Data, forKey defaultName: UserDefaultName) {
        set(data, forKey: defaultName.rawValue)
    }

    func dictionary(forKey defaultName: UserDefaultName) -> [String: Any]? {
        return dictionary(forKey: defaultName.rawValue)
    }

    func set(dictionary: [String: Any], forKey defaultName: UserDefaultName) {
        set(dictionary, forKey: defaultName.rawValue)
    }
}

struct UserDefaultName: RawRepresentable {
    typealias RawValue = String

    let rawValue: String

    init(rawValue: String) {
        self.rawValue = "com.invi.invi.app." + rawValue
    }
}
