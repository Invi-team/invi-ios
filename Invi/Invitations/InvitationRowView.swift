//
//  InvitationRowView.swift
//  Invi
//
//  Created by Marcin Mucha on 07/11/2021.
//

import SwiftUI
import CasePaths

class InvitationRowViewModel: Identifiable, ObservableObject {
    enum Route {
        case details(Invitation)
    }

    @Published var invitation: Invitation
    @Published var route: Route?

    init(invitation: Invitation, route: Route? = nil) {
        self.invitation = invitation
        self.route = route
    }

    func setDetailsNavigation(isActive: Bool) {
        route = isActive ? .details(invitation) : nil
    }
}

struct InvitationRowView: View {
    @ObservedObject var viewModel: InvitationRowViewModel

    var body: some View {
        NavigationLink(
            unwrap: $viewModel.route,
            case: /InvitationRowViewModel.Route.details,
            onNavigate: viewModel.setDetailsNavigation(isActive:),
            destination: { invitation in
                InvitationDetailsView(invitation: invitation)
            },
            label: {
                VStack(alignment: .leading, spacing: 8) {
                    Image(uiImage: viewModel.invitation.photo)
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
    var photo: UIImage {
        switch photoId {
        case .some(2):
            return UIImage(named: "invitation_image_type_2")!
        case .some(3):
            return UIImage(named: "invitation_image_type_3")!
        case .some(4):
            return UIImage(named: "invitation_image_type_4")!
        case .some(5):
            return UIImage(named: "invitation_image_type_5")!
        default:
            return UIImage(named: "invitation_image_type_1")!
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
        ], guests: [])))
    }
}