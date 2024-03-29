//
//  InviClient.swift
//  Invi
//
//  Created by Marcin Mucha on 11/11/2021.
//

import Foundation
import WebService

extension InviClient {
    enum ClientError: Error {
        case noInvitation
        case failedToEncodeGuestStatus
    }

    public static func live(configuration: Configuration) -> Self {
        let webService = WebService(decoder: JSONDecoder.inviDecoder)
        return Self.live(
            environment: configuration.environment,
            webService: webService,
            authenticatedSession: configuration.authenticatedSession
        )
    }

    static func live(
        environment: @escaping () -> ApiEnvironment,
        webService: WebServiceType,
        authenticatedSession: @escaping () -> URLSessionType?
    ) -> Self {
        return InviClient(
            invitations: {
                let request = URLRequest(url: environment().baseURL.appendingPathComponent("invitations"))
                return try await webService.get(request: request, customSession: authenticatedSession())
            },
            invitation: { invitationId in
                let request = URLRequest(url: environment().baseURL.appendingPathComponent("invitations"))

                let invitations: [Invitation] = try await webService.get(request: request, customSession: authenticatedSession())
                if let invitation = invitations.first(where: { $0.id == invitationId }) {
                    return invitation
                } else {
                    throw ClientError.noInvitation
                }
            }, putGuestStatus: { guestId, status in
                let model = GuestStatusBody(guestId: guestId, status: status)
                let url = environment().baseURL
                    .appendingPathComponent("invitation")
                    .appendingPathComponent("guest-status")
                try await webService.put(model: model, request: URLRequest(url: url), customSession: authenticatedSession())
            }, redeemInvitation: { code in
                struct Empty: Encodable {}
                let url = environment().baseURL
                    .appendingPathComponent("invitation")
                    .appendingPathComponent("\(code)")
                try await webService.post(model: Empty?.none, request: URLRequest(url: url), customSession: authenticatedSession())
            }
        )
    }

    private struct GuestStatusBody: Encodable {
        let guestId: String
        let status: Guest.Status
    }
}

extension JSONDecoder {
    static var inviDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = JSONDecoder.flexibleDateDecoding
        return decoder
    }
}
