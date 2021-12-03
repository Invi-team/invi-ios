//
//  File.swift
//  
//
//  Created by Marcin Mucha on 03/12/2021.
//

import Foundation

extension JSONDecoder {
    public static let flexibleDateDecoding: DateDecodingStrategy = .custom { decoder in
        let container = try decoder.singleValueContainer()
        let dateString = try container.decode(String.self)
        if let date = fractionalSecondsIsoDateFormatter.date(from: dateString) {
            return date
        } else if let date = isoDateFormatter.date(from: dateString) {
            return date
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
        }
    }

    private static var fractionalSecondsIsoDateFormatter: ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }

    private static let isoDateFormatter = ISO8601DateFormatter()
}
