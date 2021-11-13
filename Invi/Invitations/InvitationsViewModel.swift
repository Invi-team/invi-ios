//
//  InvitationsViewModel.swift
//  Invi
//
//  Created by Marcin Mucha on 03/10/2021.
//

import Foundation
import Combine
import InviClient

final class InvitationsViewModel: ObservableObject {
    typealias Dependencies = HasInviClient & HasAuthenticator

    enum State {
        case initial
        case loading
        case loaded([InvitationRowViewModel])
        case error(Error)
    }

    enum Route {
        case details(Invitation)
    }

    @Published var state: State = .initial
    @Published var route: Route?

    private let dependencies: Dependencies
    private var cancellables: Set<AnyCancellable> = []

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    @MainActor
    func load() async {
        state = .loading
        do {
            let invitations = try await dependencies.inviClient.invitations()
            state = .loaded(invitations.map { InvitationRowViewModel(invitation: $0, dependencies: dependencies) })
        } catch {
            state = .error(error)
        }
    }

    func logout() {
        dependencies.authenticator.logout()
    }
}
