//
//  InvitationsViewModel.swift
//  Invi
//
//  Created by Marcin Mucha on 03/10/2021.
//

import Foundation
import Combine

final class InvitationsViewModel: ObservableObject {
    typealias Dependencies = HasWebService & HasAppConfiguration & HasAuthenticator

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
            let invitations = try await InvitationsEndpointService.invitations(dependencies: dependencies)
            state = .loaded(invitations.map { InvitationRowViewModel(invitation: $0, dependencies: dependencies) })
        } catch {
            state = .error(error)
        }
    }

    func logout() {
        dependencies.authenticator.logout()
    }
}

enum InvitationsEndpointService {
    static func invitations(dependencies: HasWebService & HasAppConfiguration) async throws -> [Invitation] {
        let request = URLRequest(url: dependencies.configuration.apiEnviroment.baseURL.appendingPathComponent("invitations"))
        return try await dependencies.webService.get(request: request, authenticate: true).value
    }
}
