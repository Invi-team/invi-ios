//
//  InvitationDetailsViewModel.swift
//  Invi
//
//  Created by Marcin Mucha on 10/11/2021.
//

import SwiftUI
import Combine
import InviClient
import CasePaths

enum GuestStatusSavingState {
    case loading(id: String)
    case idle
    case failed
}

class InvitationDetailsViewModel: ObservableObject {
    typealias Dependencies = HasInviClient & HasApplication

    enum State {
        case loading
        case loaded(Invitation)
        case error(Error)

        var isLoaded: Bool {
            guard case .loaded = self else { return false }
            return true
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
            var invitation = try await dependencies.inviClient.invitation(invitationId)
            invitation.guests = invitation.guests.sortByInvitedFirst()
            state = .loaded(invitation)
        } catch {
            state = .error(error)
        }
    }

    func okAlertTapped() {
        route = nil
    }
    
    func makePhoneCall(with number: String) {
        guard let url = URL(string: "tel://\(number.removingSpaces)") else { return }
        if dependencies.application.canOpenUrl(url) {
            dependencies.application.openUrl(url)
        } else {
            debugPrint("Not able to make a call")
        }
    }
}

class GuestViewModel: ObservableObject {
    typealias Dependencies = HasInviClient

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
            try await dependencies.inviClient.putGuestStatus(guest.id, status)
            statusSavingState.wrappedValue = .idle
            debugPrint("Successful save")
        } catch {
            debugPrint(error)
            statusSavingState.wrappedValue = .failed
            throw error
        }
    }
}

private extension Array where Element == Guest {
    func sortByInvitedFirst() -> [Guest] {
        return sorted(by: { $0.type.rawValue > $1.type.rawValue })
    }
}

private extension String {
    var removingSpaces: String {
        return replacingOccurrences(of: " ", with: "")
    }
}
