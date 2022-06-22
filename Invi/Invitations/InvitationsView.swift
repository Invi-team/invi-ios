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
                    if invitations.isEmpty {
                        NoInvitationsView()
                    } else {
                        List {
                            ForEach(invitations) { viewModel in
                                InvitationRowView(viewModel: viewModel)
                            }
                        }
                    }
                case .error:
                    Text("Error occured")
                    Button("Retry", action: {
                        Task { @MainActor in await viewModel.load() }
                    })
                }
            }
            .navigationTitle(Strings.Tab.invitations)
            .toolbar {
                ToolbarItem {
                    HStack(spacing: 16) {
                        Button {
                            Task { await viewModel.load() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                        Button {
                            viewModel.addButtonTapped()
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
        }
        .task {
            Task { @MainActor in await viewModel.load() }
        }
        .sheet(unwrap: $viewModel.route, case: /InvitationsViewModel.Route.add) { addViewModel in
            NavigationView {
                AddInvitationView(viewModel: addViewModel.wrappedValue)
                    .onReceive(addViewModel.wrappedValue.$state) { state in
                        if state == .success {
                            Task {
                                await viewModel.load()
                            }
                        }
                    }
                    .toolbar {
                        ToolbarItem {
                            Button("Cancel") {
                                viewModel.cancelButtonTapped()
                            }
                        }
                    }
                    .navigationTitle("Add invitation")
            }
        }
    }
}

struct NoInvitationsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(Images.loveLetter)
            Text("Add first invitation")
                .font(.title)
            Text("Add the invitation you've received using the invitation code.")
                .font(.body)
                .fontWeight(.light)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 44)
        Spacer()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = InvitationsViewModel(
            dependencies: CustomDependencies(
                inviClient: .empty
            )
        )
        InvitationsView(viewModel: viewModel)
    }
}

private extension InvitationsViewModel.State {
}
