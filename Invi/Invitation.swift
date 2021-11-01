//
//  Invitation.swift
//  Invi
//
//  Created by Marcin Mucha on 03/10/2021.
//

import Foundation

struct Invitation: Identifiable {
    let id: String
    let invitationCode: String
    let eventId: String
    let description: Int?
    let eventDate: Date?
    let responseDateDeadline: Date?
    let receivedAt: Date?
    let photoId: Int?
    let locations: [Location]
    let organisers: [Organiser]
    let guests: [Guest]
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

struct Location {
    enum LocationType: String, Decodable {
        case wedding = "WEDDING"
        case party = "WEDDING_PARTY"
    }
    let name: String
    let address: String
    let longitude: String
    let latitude: String
    let type: LocationType
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

struct Organiser: Decodable {
    enum OrganiserType: String, Decodable {
        case bride = "BRIDE"
        case groom = "GROOM"
    }
    let id: String
    let name: String
    let surname: String
    let phoneNumber: String
    let type: OrganiserType
}

struct Guest {
    enum GuestType: String, Decodable {
        case invited = "INVITED"
        case companion = "COMPANION"
    }

    enum Status: String, Decodable {
        case undecided
        case accepted
        case declined

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let rawValue = try? container.decode(String.self), let status = Status(rawValue: rawValue) {
                self = status
            } else {
                self = .undecided
            }
        }
    }

    let id: String
    let name: String?
    let surname: String?
    let status: Status
    let type: GuestType
}

extension Guest: Decodable {
    enum CodingKeys: String, CodingKey {
        case id = "guestId"
        case name
        case surname
        case status
        case type
    }
}
