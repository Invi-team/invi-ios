//
//  RootView.swift
//  Invi
//
//  Created by Marcin Mucha on 12/11/2021.
//

import Foundation
import SwiftUI
import Combine
import InviAuthenticator
import CasePaths

struct RootView: View {
    @ObservedObject var viewModel: RootViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Group {
            switch viewModel.state {
            case .loginWall:
                LoginWallView(viewModel: LoginWallViewModel(dependencies: viewModel.dependencies))
            case .open:
                HomeTabView(viewModel: HomeTabViewModel(dependencies: viewModel.dependencies))
            }
        }
        .sheet(isPresented: $viewModel.debugMenuPresented) {
            DebugView(viewModel: DebugViewModel(dependencies: viewModel.dependencies))
        }
        .onShake {
            viewModel.openDebugMenu()
        }
    }
}

final class RootViewModel: ObservableObject {
    enum RootState {
        case loginWall
        case open
    }

    var debugMenuPresented: Bool = false {
        willSet {
            guard !dependencies.configuration.isAppStore else { return }
            objectWillChange.send()
        }
    }

    private(set) var state: RootState {
        willSet {
            guard state != newValue else { return }
            UIApplication.shared.dismissToRootViewController()
            objectWillChange.send()
        }
    }

    let dependencies: InviDependencies

    private var observation: AnyCancellable?

    init(dependencies: InviDependencies) {
        self.dependencies = dependencies
        state = Self.rootState(for: dependencies.authenticator.state.value)
        observation = dependencies.authenticator.state
            .removeDuplicates()
            .print()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.state = Self.rootState(for: state)
            }
    }

    func openDebugMenu() {
        guard !dependencies.configuration.isAppStore else { return }
        debugMenuPresented = true
    }

    private static func rootState(for authenticatorState: Authenticator.State) -> RootState {
        switch authenticatorState {
        case .loggedOut:
            return .loginWall
        case .loggedIn:
            return .open
        }
    }
}

private extension UIApplication {
    func dismissToRootViewController() {
        guard let windowScene = connectedScenes.first as? UIWindowScene else { return }
        windowScene.windows.first?.rootViewController?.dismiss(animated: true)
    }
}
