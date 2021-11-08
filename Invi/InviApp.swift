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
        case .loginWall:
            LoginWallView(viewModel: LoginWallViewModel(dependencies: dependencies))
        case .open:
            InvitationsView(viewModel: InvitationsViewModel(dependencies: dependencies))
        }
    }
}

final class RootViewModel: ObservableObject {
    enum RootState {
        case loginWall
        case open
    }

    private(set) var state: RootState {
        willSet {
            guard state != newValue else { return }
            UIApplication.shared.dismissToRootViewController()
            objectWillChange.send()
        }
    }

    private var observation: AnyCancellable?

    init(dependencies: InviDependencies) {
        state = Self.state(for: dependencies.authenticator.state.value, dependencies: dependencies)
        observation = dependencies.authenticator.state
            .removeDuplicates()
            .print()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.state = Self.state(for: state, dependencies: dependencies)
            }
    }

    private static func state(for authenticatorState: Authenticator.State, dependencies: InvitationsViewModel.Dependencies) -> RootState {
        switch authenticatorState {
        case .loggedOut:
            return .loginWall
        case .loggedIn:
            return .open
        }
    }
}

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        return true
    }
}

private extension UIApplication {
    func dismissToRootViewController() {
        guard let windowScene = connectedScenes.first as? UIWindowScene else { return }
        windowScene.windows.first?.rootViewController?.dismiss(animated: true)
    }
}
