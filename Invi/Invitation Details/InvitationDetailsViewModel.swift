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

    func loadInvitation() {
        guard !state.isLoaded else { return }
        state = .loading
        InvitationEndpointService.invitation(id: invitationId, dependencies: dependencies)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .failure(let error):
                    self?.state = .error(error)
                case .finished:
                    break
                }
            }, receiveValue: { [weak self] invitation in
                var invitation = invitation
                invitation.guests = invitation.guests.sortByInvitedFirst()
                self?.state = .loaded(invitation)
            })
            .store(in: &cancellables)
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

    func saveGuest(status: Guest.Status, for guest: Guest, onSucceed: @escaping () -> Void) {
        guard guest.status != status else { return }
        statusSavingState.wrappedValue = .loading(id: guest.id)
        InvitationEndpointService.postInvitation(guestId: guest.id, status: status, dependencies: dependencies)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .failure(let error):
                    debugPrint(error)
                    self?.statusSavingState.wrappedValue = .failed
                case .finished:
                    break
                }
            }, receiveValue: { [weak self] _ in
                self?.statusSavingState.wrappedValue = .idle
                onSucceed()
                debugPrint("Successful save")
            })
            .store(in: &cancellables)
    }
}

private enum InvitationEndpointService {
    enum Error: Swift.Error {
        case noInvitation
        case failedToEncodeGuestStatus
    }

    static func invitation(id: String, dependencies: HasWebService & HasAppConfiguration) -> AnyPublisher<Invitation, Swift.Error> {
        let request = URLRequest(url: dependencies.configuration.apiEnviroment.baseURL.appendingPathComponent("invitations"))
        let resource: WebResource<[Invitation]> = WebResource(request: request, authenticated: true)
        return dependencies.webService.load(resource: resource)
            .tryMap { invitations in
                if let invitation = invitations.first(where: { $0.id == id }) {
                    return invitation
                } else {
                    throw Error.noInvitation
                }
            }
            .eraseToAnyPublisher()
    }

    struct GuestStatusBody: Encodable {
        let guestId: String
        let status: Guest.Status
    }

    static func postInvitation(guestId: String, status: Guest.Status, dependencies: HasWebService & HasAppConfiguration) -> AnyPublisher<Data, Swift.Error> {
        let body = GuestStatusBody(guestId: guestId, status: status)
        let url = dependencies.configuration.apiEnviroment.baseURL
            .appendingPathComponent("invitation")
            .appendingPathComponent("guest-status")

        guard let data = try? JSONEncoder().encode(body) else {
            return Fail(error: Error.failedToEncodeGuestStatus)
                .eraseToAnyPublisher()
        }
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.httpBody = data
        return dependencies.webService.load(request: request, authenticated: true)
            .eraseToAnyPublisher()
    }
}

private extension Array where Element == Guest {
    func sortByInvitedFirst() -> [Guest] {
        return sorted(by: { $0.type.rawValue > $1.type.rawValue })
    }
}
