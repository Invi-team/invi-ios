//
//  InvitationRowView.swift
//  Invi
//
//  Created by Marcin Mucha on 07/11/2021.
//

import SwiftUI
import CasePaths
import InviClient

class InvitationRowViewModel: Identifiable, ObservableObject {
    typealias Dependencies = InvitationDetailsViewModel.Dependencies
    enum Route {
        case details(InvitationDetailsViewModel)
    }

    @Published var invitation: Invitation
    @Published var route: Route?

    private let dependencies: Dependencies

    init(invitation: Invitation, route: Route? = nil, dependencies: Dependencies) {
        self.invitation = invitation
        self.route = route
        self.dependencies = dependencies
    }

    func setDetailsNavigation(isActive: Bool) {
        route = isActive ? .details(InvitationDetailsViewModel(invitationId: invitation.id, invitationName: invitation.eventName, dependencies: dependencies)) : nil
    }
}

struct InvitationRowView: View {
    @ObservedObject var viewModel: InvitationRowViewModel

    var body: some View {
        NavigationLink(
            unwrap: $viewModel.route,
            case: /InvitationRowViewModel.Route.details,
            onNavigate: viewModel.setDetailsNavigation(isActive:),
            destination: { viewModel in
                InvitationDetailsView(viewModel: viewModel.wrappedValue)
            },
            label: {
                VStack(alignment: .leading, spacing: 8) {
                    Image(viewModel.invitation.photoName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                    Text(viewModel.invitation.eventName)
                        .font(.title)
                    Text(viewModel.invitation.eventDate.formatted(date: .long, time: .omitted))
                        .font(.headline)
                    Text(viewModel.invitation.desriptionString)
                        .font(.caption)
                }
            }
        )
    }
}

private extension Invitation {
    var photoName: String {
        switch photoId {
        case .some(2):
            return Images.invitationImage2
        case .some(3):
            return Images.invitationImage3
        case .some(4):
            return Images.invitationImage4
        case .some(5):
            return Images.invitationImage5
        default:
            return Images.invitationImage1
        }
    }

    var desriptionString: String {
        switch description {
        case .some(2):
            return Strings.Invitations.description2
        case .some(3):
            return Strings.Invitations.description3
        case .some(4):
            return Strings.Invitations.description4
        case .some(5):
            return Strings.Invitations.description5
        default:
            return Strings.Invitations.description1
        }
    }
}

struct InvitationRowView_Previews: PreviewProvider {
    static var previews: some View {
        InvitationRowView(viewModel: InvitationRowViewModel(invitation: Invitation(id: "", invitationCode: "", eventId: "", description: 1, eventDate: .now, responseDateDeadline: nil, receivedAt: nil, photoId: 1, locations: [
            Location(name: "Kraków", address: "Kościół św. Anny", longitude: "50", latitude: "20", type: .wedding),
            Location(name: "Kraków", address: "Hotel Sheraton", longitude: "50", latitude: "20", type: .party)
        ], organisers: [
            Organiser(id: "937123", name: "Jan", surname: "Kowalski", phoneNumber: "123456789", type: .groom),
            Organiser(id: "937124", name: "Katarzyna", surname: "Nowak", phoneNumber: "123456781", type: .bride)
        ], guests: []), dependencies: CustomDependencies()))
    }
}
