//
//  SceneDelegate.swift
//  Invi
//
//  Created by Marcin Mucha on 20/05/2021.
//

import UIKit
import SwiftUI
import Combine

@main
class InviApp: App {
    private let inviDependencies: InviDependencies
    @State var state: Authenticator.State = .none

    private var cancellable: AnyCancellable?

    required init() {
        inviDependencies = Dependencies()
        cancellable = inviDependencies.authenticator.state.sink { state in
            self.state = state
        }
    }

    var body: some Scene {
        WindowGroup {
            switch state {
            case .none, .loggedOut, .evaluating:
                LoginOnboardingView(dependencies: inviDependencies)
            case .loggedIn:
                ContentView()
            }
        }
    }
}

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }
}
