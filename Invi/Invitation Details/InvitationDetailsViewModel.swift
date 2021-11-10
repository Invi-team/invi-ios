//
//  InvitationDetailsViewModel.swift
//  Invi
//
//  Created by Marcin Mucha on 10/11/2021.
//

import SwiftUI
import Combine
import CasePaths

enum GuestStatusSavingState {
    case loading(id: String)
    case idle
    case failed
}

class InvitationDetailsViewModel: ObservableObject {
    typealias Dependencies = HasWebService & HasAppConfiguration

    enum State {
        case loading
        case loaded(Invitation)
        case error(Error)

        var isLoaded: Bool {
            (/State.loaded).extract(from: self) != nil
        }
    }

    enum Route {
        case errorAlert
    }

    @Published var state: State
    @Published var route: Route?
    @Published var statusSavingState: GuestStatusSavingState = .idle

    private let invitationId: String
    private let invitationName: String
    let dependencies: Dependencies
    private var cancellables: Set<AnyCancellable> = []

    init(invitationId: String, invitationName: String, state: State = .loading, dependencies: Dependencies) {
        self.invitationId = invitationId
        self.invitationName = invitationName
        self.state = state
        self.dependencies = dependencies

        Task { @MainActor in
            for await statusState in $statusSavingState.values
            where (/GuestStatusSavingState.failed).extract(from: statusState) != nil {
                route = .errorAlert
            }
        }
    }

    @MainActor
    func loadInvitation() async {
        guard !state.isLoaded else { return }
        state = .loading
        do {
            var invitation = try await InvitationEndpointService.invitation(id: invitationId, dependencies: dependencies)
            invitation.guests = invitation.guests.sortByInvitedFirst()
            state = .loaded(invitation)
        } catch {
            state = .error(error)
        }
    }

    func okAlertTapped() {
        route = nil
    }
}

class GuestViewModel: ObservableObject {
    typealias Dependencies = HasWebService & HasAppConfiguration

    var guest: Binding<Guest>
    var statusSavingState: Binding<GuestStatusSavingState>

    private let dependencies: Dependencies
    private var cancellables: Set<AnyCancellable> = []

    init(guest: Binding<Guest>, statusSavingState: Binding<GuestStatusSavingState>, dependencies: Dependencies) {
        self.guest = guest
        self.statusSavingState = statusSavingState
        self.dependencies = dependencies
    }

    @MainActor
    func saveGuest(status: Guest.Status, for guest: Guest) async throws {
        guard guest.status != status else { return }
        statusSavingState.wrappedValue = .loading(id: guest.id)
        do {
            try await InvitationEndpointService.putInvitation(guestId: guest.id, status: status, dependencies: dependencies)
            statusSavingState.wrappedValue = .idle
            debugPrint("Successful save")
        } catch {
            debugPrint(error)
            statusSavingState.wrappedValue = .failed
            throw error
        }
    }
}

private enum InvitationEndpointService {
    enum Error: Swift.Error {
        case noInvitation
        case failedToEncodeGuestStatus
    }

    static func invitation(id: String, dependencies: HasWebService & HasAppConfiguration) async throws -> Invitation {
        let request = URLRequest(url: dependencies.configuration.apiEnviroment.baseURL.appendingPathComponent("invitations"))

        let invitations: [Invitation] = try await dependencies.webService.get(request: request, authenticate: true).value
        if let invitation = invitations.first(where: { $0.id == id }) {
            return invitation
        } else {
            throw Error.noInvitation
        }
    }

    struct GuestStatusBody: Encodable {
        let guestId: String
        let status: Guest.Status
    }

    static func putInvitation(guestId: String, status: Guest.Status, dependencies: HasWebService & HasAppConfiguration) async throws {
        let model = GuestStatusBody(guestId: guestId, status: status)
        let url = dependencies.configuration.apiEnviroment.baseURL
            .appendingPathComponent("invitation")
            .appendingPathComponent("guest-status")
        _ = try await dependencies.webService.put(model: model, request: URLRequest(url: url), authenticate: true)
    }
}

private extension Array where Element == Guest {
    func sortByInvitedFirst() -> [Guest] {
        return sorted(by: { $0.type.rawValue > $1.type.rawValue })
    }
}
