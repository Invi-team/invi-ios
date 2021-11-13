//
//  InviClient.swift
//  Invi
//
//  Created by Marcin Mucha on 11/11/2021.
//

import Foundation
import WebService

extension InviClient {
    enum Error: Swift.Error {
        case noInvitation
        case failedToEncodeGuestStatus
    }

    public static func live(environment: ApiEnvironment, userToken: @escaping () -> String?) -> Self {
        let webService = WebService(userToken: userToken)
        return Self.live(environment: environment, webService: webService)
    }

    static func live(environment: ApiEnvironment, webService: WebServiceType) -> Self {
        return InviClient(
            invitations: {
                let request = URLRequest(url: environment.baseURL.appendingPathComponent("invitations"))
                return try await webService.get(request: request).value
            },
            invitation: { invitationId in
                let request = URLRequest(url: environment.baseURL.appendingPathComponent("invitations"))

                let invitations: [Invitation] = try await webService.get(request: request).value
                if let invitation = invitations.first(where: { $0.id == invitationId }) {
                    return invitation
                } else {
                    throw Error.noInvitation
                }

            }, putGuestStatus: { guestId, status in
                let model = GuestStatusBody(guestId: guestId, status: status)
                let url = environment.baseURL
                    .appendingPathComponent("invitation")
                    .appendingPathComponent("guest-status")
                _ = try await webService.put(model: model, request: URLRequest(url: url))
            }
        )
    }

    private struct GuestStatusBody: Encodable {
        let guestId: String
        let status: Guest.Status
    }
}
