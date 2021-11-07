//
//  InvitationDetailsView.swift
//  Invi
//
//  Created by Marcin Mucha on 07/11/2021.
//

import SwiftUI

struct InvitationDetailsView: View {
    @Binding var invitation: Invitation

    var body: some View {
        Form {
            Section("Guests") {
                ForEach($invitation.guests) { $guest in
                    Picker(guest.readableNameAndSurname, selection: $guest.status) {
                        ForEach(Guest.Status.allCases, id: \.self) { status in
                            Text(status.rawValue)
                        }
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

struct InvitationDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        InvitationDetailsView(invitation: .constant(Invitation(id: "", invitationCode: "", eventId: "", description: nil, eventDate: Date.now, responseDateDeadline: nil, receivedAt: nil, photoId: nil, locations: [], organisers: [], guests: [])))
    }
}
