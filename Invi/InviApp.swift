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
struct InviApp: App {
    let inviDependencies: InviDependencies

    init() {
        inviDependencies = Dependencies()
    }

    var body: some Scene {
        WindowGroup {
            RootView(dependencies: inviDependencies)
        }
    }
}

struct RootView: View {
    @ObservedObject var viewModel: RootViewModel

    private let dependencies: InviDependencies

    init(dependencies: InviDependencies) {
        self.dependencies = dependencies
        self.viewModel = RootViewModel(dependencies: dependencies)
    }

    var body: some View {
        switch viewModel.state {
        case .none, .loggedOut, .evaluating:
            LoginOnboardingView(dependencies: dependencies)
        case .loggedIn:
            ContentView(viewModel: ContentViewModel(dependencies: dependencies))
        }
    }
}

final class RootViewModel: ObservableObject {
    typealias Dependencies = HasAuthenticator

    @Published var state: Authenticator.State = .none

    init(dependencies: Dependencies) {
        dependencies.authenticator.state.print().assign(to: &$state)
    }
}

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }
}
