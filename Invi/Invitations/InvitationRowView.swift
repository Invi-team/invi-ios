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
                Text(viewModel.invitation.id)
            }
        )
    }
}

struct InvitationRowView_Previews: PreviewProvider {
    static var previews: some View {
        InvitationRowView(viewModel: InvitationRowViewModel(invitation: Invitation(id: "", invitationCode: "", eventId: "", description: nil, eventDate: .now, responseDateDeadline: nil, receivedAt: nil, photoId: nil, locations: [], organisers: [], guests: [])))
    }
}
