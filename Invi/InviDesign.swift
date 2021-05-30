//
//  InviDesign.swift
//  Invi
//
//  Created by Michal Gorzalczany on 30/05/2021.
//

import Foundation
import SwiftUI

enum InviDesign {
    enum Colors {
        enum Background {
            static let purple = Color(fromHexString: "#C2BCEA")!
            static let grey = Color(fromHexString: "#333333")!
        }
    }
    enum Layout {
        enum Button {
            static let cornerRadius: CGFloat = 8
        }
    }
}

extension SwiftUI.Color {
    init?(fromHexString hexString: String?) {
        guard let hexString = hexString else { return nil }
        let hexPattern = "^#[a-fA-F0-9]+$"
        guard hexString.range(of: hexPattern, options: .regularExpression) != nil else { return nil }
        let hex = hexString.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b, a: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (r, g, b, a) = ((int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17, 255)
        case 6: // RGB (24-bit)
            (r, g, b, a) = (int >> 16, int >> 8 & 0xFF, int & 0xFF, 255)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: Double(a) / 255)
    }
}
