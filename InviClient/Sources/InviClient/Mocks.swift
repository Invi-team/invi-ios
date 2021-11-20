//
//  InviClientLive.swift
//  Invi
//
//  Created by Marcin Mucha on 12/11/2021.
//

import Foundation

extension InviClient {
    public static var happyPath: Self {
        let firstInvitation = Invitation(id: "1", invitationCode: "fake", eventId: "fake", description: 1, eventDate: Date.now, responseDateDeadline: nil, receivedAt: nil, photoId: 1, locations: [
            Location(name: "Kościół Mariacki", address: "Plac Mariacki 1", longitude: "50", latitude: "20", type: .wedding),
            Location(name: "Hotel Sheraton", address: "Powiśle 10", longitude: "50", latitude: "20", type: .party)
        ], organisers: [
            Organiser(id: "101", name: "Jan", surname: "Kowalski", phoneNumber: "123456789", type: .groom),
            Organiser(id: "102", name: "Janina", surname: "Nowak", phoneNumber: "123456788", type: .bride)
        ], guests: [
            Guest(id: "1001", name: "Michał", surname: "Nowak", status: nil, type: .invited),
            Guest(id: "1002", name: "Grażyna", surname: "Nowak", status: nil, type: .companion)
        ])
        return InviClient(
            invitations: {
                return [
                    firstInvitation,
                    Invitation(id: "2", invitationCode: "fake", eventId: "fake", description: 1, eventDate: Date.now, responseDateDeadline: nil, receivedAt: nil, photoId: 1, locations: [
                        Location(name: "Kościół Mariacki", address: "Plac Mariacki 1", longitude: "50", latitude: "20", type: .wedding),
                        Location(name: "Hotel Sheraton", address: "Powiśle 10", longitude: "50", latitude: "20", type: .party)
                    ], organisers: [
                        Organiser(id: "110", name: "Janusz", surname: "Nowak", phoneNumber: "123456789", type: .groom),
                        Organiser(id: "111", name: "Katarzyna", surname: "Kowalska", phoneNumber: "123456788", type: .bride)
                    ], guests: [
                        Guest(id: "1010", name: "Paweł", surname: "Wiśniewski", status: nil, type: .invited),
                        Guest(id: "1011", name: "Joanna", surname: "Wiśniewska", status: nil, type: .companion)
                    ])
                ]
            },
            invitation: { _ in
                return firstInvitation
            },
            putGuestStatus: { _, _ in },
            redeemInvitation: { _ in }
        )
    }

    public static var failing: Self {
        enum Error: Swift.Error {
            case fakeError
        }
        return InviClient(
            invitations: { throw Error.fakeError },
            invitation: { _ in throw Error.fakeError },
            putGuestStatus: { _, _ in throw Error.fakeError },
            redeemInvitation: { _ in throw Error.fakeError }
        )
    }

    public static var empty: Self {
        enum Error: Swift.Error {
            case fakeError
        }
        return InviClient(
            invitations: { [] },
            invitation: { _ in throw Error.fakeError },
            putGuestStatus: { _, _ in throw Error.fakeError },
            redeemInvitation: { _ in throw Error.fakeError }
        )
    }
}
