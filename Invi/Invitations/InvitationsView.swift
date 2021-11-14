//
//  ContentView.swift
//  Invi
//
//  Created by Marcin Mucha on 20/05/2021.
//

import Combine
import SwiftUI
import CasePaths
import InviClient

struct InvitationsView: View {
    @StateObject var viewModel: InvitationsViewModel

    var body: some View {
        NavigationView {
            VStack {
                switch viewModel.state {
                case .initial:
                    EmptyView()
                case .loading:
                    ProgressView()
                case .loaded(let invitations):
                    List {
                        ForEach(invitations) { viewModel in
                            InvitationRowView(viewModel: viewModel)
                        }
                    }
                case .error:
                    Text("Error occured")
                    Button("Retry", action: {
                        Task { @MainActor in await viewModel.load() }
                    })
                }
            }
            .navigationTitle("Invitation")
            .toolbar {
                Button("Logout") { viewModel.logout() }
            }
        }.task {
            Task { @MainActor in await viewModel.load() }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = InvitationsViewModel(
            dependencies: CustomDependencies(
                inviClient: .happyPath
            )
        )
        InvitationsView(viewModel: viewModel)
    }
}

private extension InvitationsViewModel.State {
}
