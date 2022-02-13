//
//  InvitationDetailsView.swift
//  Invi
//
//  Created by Marcin Mucha on 07/11/2021.
//

import SwiftUI
import Combine
import CasePaths
import InviClient

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
                                GuestView(viewModel: GuestViewModel(guest: $guest, statusSavingState: $viewModel.statusSavingState, dependencies: viewModel.dependencies))
                            }
                        }
                    }
                    Section("Wedding couple") {
                        ForEach(invitation.organisers) { organiser in
                            HStack(spacing: 8) {
                                Image(systemName: "person")
                                Text("\(organiser.name) \(organiser.surname)")
                                    .padding(.trailing)
                                Button {
                                    viewModel.makePhoneCall(with: organiser.phoneNumber)
                                } label: {
                                    Image(systemName: "phone.fill")
                                }
                            }
                        }
                    }
                    Section("Wedding") {
                        LocationView(viewModel: LocationViewModel(), location: invitation.wedding, date: invitation.eventDate)
                    }
                    Section("Wedding party") {
                        LocationView(viewModel: LocationViewModel(), location: invitation.party, date: nil)
                    }
                }
                .navigationTitle(invitation.eventName)
            case .error:
                Text("Error occured")
                Button("Retry", action: {
                    Task { @MainActor in await viewModel.loadInvitation() }
                })
            }
        }
        .alert(
            title: { Text("Error") },
            unwrap: $viewModel.route,
            case: /InvitationDetailsViewModel.Route.errorAlert,
            actions: {
                Button("OK", role: .cancel) {
                    viewModel.okAlertTapped()
                }
            },
            message: {
                Text("Something went wrong")
            }
        )
        .task {
            Task { @MainActor in await viewModel.loadInvitation() }
        }
    }
}

struct GuestView: View {
    @ObservedObject var viewModel: GuestViewModel

    var guest: Guest {
        viewModel.guest.wrappedValue
    }

    var body: some View {
        Menu {
            Button {
                Task { @MainActor in
                    try await viewModel.saveGuest(status: .accepted, for: guest)
                    viewModel.guest.wrappedValue.status = .accepted
                }
            } label: {
                GuestStatusLabel(title: "Accepted", systemImage: guest.status == .accepted ? "checkmark" : nil)
            }
            Button {
                Task { @MainActor in
                    try await viewModel.saveGuest(status: .declined, for: guest)
                    viewModel.guest.wrappedValue.status = .declined
                }
            } label: {
                GuestStatusLabel(title: "Declined", systemImage: guest.status == .declined ? "checkmark" : nil)
            }
        } label: {
            HStack {
                Text(guest.readableNameAndSurname)
                Spacer()
                if isSaving {
                    ProgressView()
                } else {
                    switch guest.status {
                    case .some(.accepted):
                        Label("Accepted", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    case .some(.declined):
                        Label("Declined", systemImage: "x.circle.fill")
                            .foregroundColor(.red)
                    case .none:
                        Label("Undecided", systemImage: "questionmark.circle.fill")
                    }
                }
            }
        }.disabled(isSaving)
    }

    var isSaving: Bool {
        (/GuestStatusSavingState.loading).extract(from: viewModel.statusSavingState.wrappedValue) == guest.id
    }
}

private struct LocationView: View {
    let viewModel: LocationViewModel
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
                    Text(date.formatted(Date.FormatStyle.eventFormatStyle.hour().minute()))
                }
            }
            if let location = location {
                HStack(spacing: 8) {
                    Image(systemName: "mappin")
                    Text("\(location.name) \n\(location.address)")
                }
                Button("Navigate") {
                    viewModel.navigateTo(location: location)
                }
            } else {
                Text("Location to be announced.")
            }
        }
    }
}

private struct GuestStatusLabel: View {
    let title: String
    let systemImage: String?

    var body: some View {
        if let systemImage = systemImage {
            Label(title, systemImage: systemImage)
        } else {
            Text(title)
        }
    }
}

struct InvitationDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        InvitationDetailsView(viewModel: InvitationDetailsViewModel(invitationId: "", invitationName: "", state: .loaded(Invitation(id: "", invitationCode: "", eventId: "", description: nil, eventDate: Date.now, responseDateDeadline: nil, receivedAt: nil, photoId: nil, locations: [], organisers: [], guests: [])), dependencies: CustomDependencies()))
    }
}

private extension Date.FormatStyle {
    static var eventFormatStyle: Date.FormatStyle {
        var formatStyle = Date.FormatStyle.dateTime
        formatStyle.timeZone = TimeZone(abbreviation: "UTC")!
        return formatStyle
    }
}
