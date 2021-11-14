//
//  SceneDelegate.swift
//  Invi
//
//  Created by Marcin Mucha on 20/05/2021.
//

import UIKit
import SwiftUI
import Combine
import InviClient

@main
struct InviApp: App {
    let inviDependencies: InviDependencies

    init() {
        inviDependencies = LiveDependencies()
    }

    var body: some Scene {
        WindowGroup {
            RootView(viewModel: RootViewModel(dependencies: inviDependencies))
        }
    }
}
