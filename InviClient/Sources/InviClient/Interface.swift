//
//  InviClientInterface.swift
//  Invi
//
//  Created by Marcin Mucha on 12/11/2021.
//

import Foundation
import UIKit

public struct InviClient {
    public var invitations: () async throws -> [Invitation]
    public var invitation: (_ id: String) async throws -> Invitation
    public var putGuestStatus: (_ guestId: String, _ status: Guest.Status) async throws -> Void
    public var redeemInvitation: (_ code: Int) async throws -> Void

    public init(
        invitations: @escaping () async throws -> [Invitation],
        invitation: @escaping  (_ id: String) async throws -> Invitation,
        putGuestStatus: @escaping  (_ guestId: String, _ status: Guest.Status) async throws -> Void,
        redeemInvitation: @escaping (_ code: Int) async throws -> Void
    ) {
        self.invitations = invitations
        self.invitation = invitation
        self.putGuestStatus = putGuestStatus
        self.redeemInvitation = redeemInvitation
    }
}

extension InviClient {
    public struct Configuration {
        let environment: () -> ApiEnvironment
        let token: () -> String?

        public init(
            environment: @escaping () -> ApiEnvironment,
            token: @escaping () -> String?
        ) {
            self.environment = environment
            self.token = token
        }
    }

    public enum ApiEnvironment: String {
        case prod
        case stage = "dev"

        public var baseURL: URL {
            return URL(string: "https://dev.invi.click/api/v1/")!
        }
    }
}

public struct Invitation: Identifiable {
    public let id: String
    public let invitationCode: String
    public let eventId: String
    public let description: Int?
    public let eventDate: Date
    public let responseDateDeadline: Date?
    public let receivedAt: Date?
    public let photoId: Int?
    public let locations: [Location]
    public let organisers: [Organiser]
    public var guests: [Guest]

    public init(
        id: String,
        invitationCode: String,
        eventId: String,
        description: Int?,
        eventDate: Date,
        responseDateDeadline: Date?,
        receivedAt: Date?,
        photoId: Int?,
        locations: [Location],
        organisers: [Organiser],
        guests: [Guest]
    ) {
        self.id = id
        self.invitationCode = invitationCode
        self.eventId = eventId
        self.description = description
        self.eventDate = eventDate
        self.responseDateDeadline = responseDateDeadline
        self.receivedAt = receivedAt
        self.photoId = photoId
        self.locations = locations
        self.organisers = organisers
        self.guests = guests
    }
}

extension Invitation: Decodable {
    enum CodingKeys: String, CodingKey {
        case id = "invitationId"
        case invitationCode
        case eventId
        case description
        case eventDate
        case responseDateDeadline
        case receivedAt
        case photoId
        case locations
        case organisers
        case guests
    }
}

public struct Location {
    public enum LocationType: String, Decodable {
        case wedding = "WEDDING"
        case party = "WEDDING_PARTY"
    }
    public let name: String
    public let address: String
    public let longitude: String
    public let latitude: String
    public let type: LocationType

    public init(name: String, address: String, longitude: String, latitude: String, type: LocationType) {
        self.name = name
        self.address = address
        self.longitude = longitude
        self.latitude = latitude
        self.type = type
    }
}

extension Location: Decodable {
    enum CodingKeys: String, CodingKey {
        case name
        case address = "addr"
        case longitude
        case latitude
        case type
    }
}

public struct Organiser: Identifiable, Decodable {
    public enum OrganiserType: String, Decodable {
        case bride = "BRIDE"
        case groom = "GROOM"
    }
    public let id: String
    public let name: String
    public let surname: String
    public let phoneNumber: String
    public let type: OrganiserType

    public init(id: String, name: String, surname: String, phoneNumber: String, type: OrganiserType) {
        self.id = id
        self.name = name
        self.surname = surname
        self.phoneNumber = phoneNumber
        self.type = type
    }
}

public struct Guest: Identifiable, Hashable {
    public enum GuestType: String, Decodable {
        case invited = "INVITED"
        case companion = "COMPANION"
    }

    public enum Status: String, CaseIterable, Codable {
        case accepted = "ACCEPTED"
        case declined = "DECLINED"
    }

    public let id: String
    public let name: String?
    public let surname: String?
    public var status: Status?
    public let type: GuestType

    public init(id: String, name: String?, surname: String?, status: Guest.Status? = nil, type: Guest.GuestType) {
        self.id = id
        self.name = name
        self.surname = surname
        self.status = status
        self.type = type
    }
}

extension Guest: Decodable {
    enum CodingKeys: String, CodingKey {
        case id = "guestId"
        case name
        case surname
        case status
        case type
    }

    public var readableNameAndSurname: String {
        var result = ""
        if let name = name {
            result.append(name)
        }
        if let surname = surname {
            result.append(" \(surname)")
        }
        return result
    }
}

extension Invitation {
    public var wedding: Location? {
        return locations.first(where: { $0.type == .wedding })
    }

    public var party: Location? {
        return locations.first(where: { $0.type == .party })
    }

    public var eventName: String {
        return organisers.map { $0.name }.compactMap { $0 }.joined(separator: " & ")
    }
}
