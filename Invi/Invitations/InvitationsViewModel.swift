//
//  InvitationsViewModel.swift
//  Invi
//
//  Created by Marcin Mucha on 03/10/2021.
//

import Foundation
import Combine
import InviClient
import CasePaths

@MainActor
final class InvitationsViewModel: ObservableObject {
    typealias Dependencies = HasInviClient & AddInvitationViewModel.Dependencies

    enum State {
        case initial
        case loading
        case loaded([InvitationRowViewModel])
        case error(Error)
    }

    enum Route {
        case details(Invitation)
        case add(AddInvitationViewModel)
    }

    @Published var state: State = .initial
    @Published var route: Route?

    private let dependencies: Dependencies
    private var cancellables: Set<AnyCancellable> = []

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func loadOnce() async {
        guard !state.isLoaded else { return }
        await load()
    }

    func load() async {
        if !state.isLoaded {
            state = .loading
        }
        do {
            let invitations = try await dependencies.inviClient.invitations()
            state = .loaded(invitations.map { InvitationRowViewModel(invitation: $0, dependencies: dependencies) })
        } catch {
            state = .error(error)
        }
    }

    func addButtonTapped() {
        route = .add(AddInvitationViewModel(dependencies: dependencies))
    }

    func cancelButtonTapped() {
        route = nil
    }
}

extension InvitationsViewModel.State {
    var isLoaded: Bool {
        (/InvitationsViewModel.State.loaded).extract(from: self) != nil
    }
}
