//
//  DebugViewModel.swift
//  Invi
//
//  Created by Marcin Mucha on 05/12/2021.
//

import Foundation

struct DebugMenuItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String?
    let kind: Kind

    enum Kind {
        case booleanValue(key: UserDefaultName)
    }
}

final class DebugViewModel: ObservableObject {
    typealias Dependencies = HasUserDefaults
    let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }
    
    let items: [DebugMenuItem] = [
        DebugMenuItem(title: "Use dev environment", description: nil, kind: .booleanValue(key: .apiDevEnvrionmentEnabled))
    ]
}

extension UserDefaultName {
    static let apiDevEnvrionmentEnabled = UserDefaultName(rawValue: "apiDevEnvrionmentEnabled")
}
