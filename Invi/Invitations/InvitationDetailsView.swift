//
//  InvitationDetailsView.swift
//  Invi
//
//  Created by Marcin Mucha on 07/11/2021.
//

import SwiftUI
import Combine
import CasePaths

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

    @Published var state: State

    private let invitationId: String
    private let invitationName: String
    let dependencies: Dependencies
    private var cancellables: Set<AnyCancellable> = []

    init(invitationId: String, invitationName: String, state: State = .loading, dependencies: Dependencies) {
        self.invitationId = invitationId
        self.invitationName = invitationName
        self.state = state
        self.dependencies = dependencies
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
}

struct InvitationDetailsView: View {
    @ObservedObject var viewModel: InvitationDetailsViewModel

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView()
            case .loaded(let invitation):
                Form {
                    Section("Guests") {
                        IfCaseLet($viewModel.state, pattern: /InvitationDetailsViewModel.State.loaded) { invitation in
                            ForEach(invitation.guests) { $guest in
                                GuestView(viewModel: GuestViewModel(guest: $guest, dependencies: viewModel.dependencies))
                            }
                        }
                    }
                    Section("Wedding couple") {
                        ForEach(invitation.organisers) { organiser in
                            HStack(spacing: 8) {
                                Image(systemName: "person")
                                Text("\(organiser.name) \(organiser.surname)")
                            }
                        }
                    }
                    Section("Wedding") {
                        LocationView(location: invitation.wedding, date: invitation.eventDate)
                    }
                    Section("Wedding party") {
                        LocationView(location: invitation.party, date: nil)
                    }
                }
                .navigationTitle(invitation.eventName)
            case .error:
                Text("Error occured")
                Button("Retry", action: { viewModel.loadInvitation() })
            }
        }.task {
            viewModel.loadInvitation()
        }
    }
}

class GuestViewModel: ObservableObject {
    typealias Dependencies = HasWebService & HasAppConfiguration

    var guest: Binding<Guest>
    @Published var isSaving: Bool = false

    private let dependencies: Dependencies
    private var cancellables: Set<AnyCancellable> = []

    init(guest: Binding<Guest>, dependencies: Dependencies) {
        self.guest = guest
        self.dependencies = dependencies
    }

    func saveGuest(status: Guest.Status, for guest: Guest, onSucceed: @escaping () -> Void) {
        guard guest.status != status else { return }
        isSaving = true
        InvitationEndpointService.postInvitation(guestId: guest.id, status: status, dependencies: dependencies)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .failure(let error):
                    // TODO: present error
                    print(error)
                    self?.isSaving = false
                case .finished:
                    break
                }
            }, receiveValue: { [weak self] _ in
                self?.isSaving = false
                onSucceed()
                print("Successful save")
            })
            .store(in: &cancellables)
    }
}

struct GuestView: View {
    @ObservedObject var viewModel: GuestViewModel

    var guest: Guest {
        viewModel.guest.wrappedValue
    }

    var body: some View {
        Menu {
            Button("Accepted", action: {
                viewModel.saveGuest(status: .accepted, for: guest) {
                    viewModel.guest.wrappedValue.status = .accepted
                }
            })
            Button("Declined", action: {
                viewModel.saveGuest(status: .declined, for: guest) {
                    viewModel.guest.wrappedValue.status = .declined
                }
            })
        } label: {
            HStack {
                Text(guest.readableNameAndSurname)
                Spacer()
                if viewModel.isSaving {
                    ProgressView()
                } else {
                    switch guest.status {
                    case .some(.accepted):
                        Label("Accepted", systemImage: "checkmark.circle.fill")
                    case .some(.declined):
                        Label("Declined", systemImage: "x.circle.fill")
                    case .none:
                        Label("Undecided", systemImage: "questionmark.circle.fill")
                    }
                }
            }
        }.disabled(viewModel.isSaving)
    }
}

private struct LocationView: View {
    let location: Location?
    let date: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let date = date {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                    Text(date.formatted(date: .long, time: .omitted))
                }
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                    Text(date.formatted(date: .omitted, time: .shortened))
                }
            }
            if let location = location {
                HStack(spacing: 8) {
                    Image(systemName: "mappin")
                    Text("\(location.name) \n\(location.address)")
                }
            } else {
                Text("Location to be announced.")
            }
            Button("Navigate") {
                // TODO
            }
        }
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

struct InvitationDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        InvitationDetailsView(viewModel: InvitationDetailsViewModel(invitationId: "", invitationName: "", state: .loaded(Invitation(id: "", invitationCode: "", eventId: "", description: nil, eventDate: Date.now, responseDateDeadline: nil, receivedAt: nil, photoId: nil, locations: [], organisers: [], guests: [])), dependencies: Dependencies()))
    }
}
