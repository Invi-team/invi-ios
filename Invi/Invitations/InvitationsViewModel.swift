//
//  InvitationsViewModel.swift
//  Invi
//
//  Created by Marcin Mucha on 03/10/2021.
//

import Foundation
import Combine

final class InvitationsViewModel: ObservableObject {
    typealias Dependencies = HasWebService & HasAppConfiguration & HasAuthenticator

    enum State {
        case initial
        case loading
        case loaded([Invitation])
        case error(Error)
    }

    @Published var state: State = .initial

    private let dependencies: Dependencies
    private var cancellables: Set<AnyCancellable> = []

    init(dependencies: Dependencies) {
        print("INIT")
        self.dependencies = dependencies
    }

    deinit {
        print("DEINIT")
    }

    func load() {
        state = .loading
        InvitationsEndpointService.invitations(dependencies: dependencies)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
            switch completion {
            case .finished:
                break
            case .failure(let error):
                self?.state = .error(error)
            }
        }, receiveValue: { [weak self] invitations in
            self?.state = .loaded(invitations)
        })
        .store(in: &cancellables)
    }

    func logout() {
        dependencies.authenticator.logout()
    }
}

private enum InvitationsEndpointService {
    static func invitations(dependencies: HasWebService & HasAppConfiguration) -> AnyPublisher<[Invitation], Error> {
        let request = URLRequest(url: dependencies.configuration.apiEnviroment.baseURL.appendingPathComponent("invitations"))
        let resource: WebResource<[Invitation]> = WebResource(request: request, authenticated: true)
        return dependencies.webService.load(resource: resource)
    }
}
