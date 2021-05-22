//
//  SceneDelegate.swift
//  Invi
//
//  Created by Marcin Mucha on 20/05/2021.
//

import UIKit
import SwiftUI

@main
struct InviApp: App {
    private let inviDependencies: InviDependencies

    init() {
        inviDependencies = Dependencies()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }
}
