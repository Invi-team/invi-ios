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

struct RootView: View {
    @ObservedObject var viewModel: RootViewModel

    var body: some View {
        switch viewModel.state {
        case .loginWall:
            LoginWallView(viewModel: LoginWallViewModel(dependencies: viewModel.dependencies))
        case .open:
            InvitationsView(viewModel: InvitationsViewModel(dependencies: viewModel.dependencies))
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

    let dependencies: InviDependencies

    private var observation: AnyCancellable?

    init(dependencies: InviDependencies) {
        self.dependencies = dependencies
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

private extension UIApplication {
    func dismissToRootViewController() {
        guard let windowScene = connectedScenes.first as? UIWindowScene else { return }
        windowScene.windows.first?.rootViewController?.dismiss(animated: true)
    }
}