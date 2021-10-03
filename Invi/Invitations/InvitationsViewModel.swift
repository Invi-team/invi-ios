//
//  InvitationsViewModel.swift
//  Invi
//
//  Created by Marcin Mucha on 03/10/2021.
//

import Foundation
import Combine

final class InvitationsViewModel: ObservableObject {
    typealias Dependencies = HasWebService & HasAppConfiguration

    enum State {
        case initial
        case loading
        case loaded([Invitation])
        case error(Error)
    }

    @Published var state: State = .initial

    private let dependencies: Dependencies
    private var cancellable: AnyCancellable?

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func load() {
        state = .loading
        cancellable = InvitationsEndpointService.invitations(dependencies: dependencies)
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
    }
}

private enum InvitationsEndpointService {
    static func invitations(dependencies: HasWebService & HasAppConfiguration) -> AnyPublisher<[Invitation], Error> {
        let resource: WebResource<[Invitation]> = WebResource(request: URLRequest(url: dependencies.configuration.apiEnviroment.baseURL.appendingPathComponent("invitations")))
        return dependencies.webService.load(resource: resource)
    }
}
