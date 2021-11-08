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

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        invitationCode = try container.decode(String.self, forKey: .invitationCode)
        eventId = try container.decode(String.self, forKey: .eventId)
        description = try container.decodeIfPresent(Int.self, forKey: .description)
        eventDate = try container.decodeIfPresent(Date.self, forKey: .eventDate)
        responseDateDeadline = try container.decodeIfPresent(Date.self, forKey: .responseDateDeadline)
        receivedAt = try? container.decode(Date.self, forKey: .receivedAt) // ignoring errors, manual decoding needed b/c server returns incorrect format for this date
        photoId = try container.decodeIfPresent(Int.self, forKey: .photoId)
        locations = try container.decode([Location].self, forKey: .locations)
        organisers = try container.decode([Organiser].self, forKey: .organisers)
        guests = try container.decode([Guest].self, forKey: .guests)
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
