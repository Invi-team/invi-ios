//
//  ContentView.swift
//  Invi
//
//  Created by Marcin Mucha on 20/05/2021.
//

import Combine
import SwiftUI
import CasePaths

struct InvitationsView: View {
    @StateObject var viewModel: InvitationsViewModel

    init(viewModel: InvitationsViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
        viewModel.load()
    }

    var body: some View {
        NavigationView {
            VStack {
                switch viewModel.state {
                case .initial:
                    EmptyView()
                case .loading:
                    ActivityIndicator(style: .large)
                case .loaded(let invitations):
                    List {
                        ForEach(invitations) { viewModel in
                            InvitationRowView(viewModel: viewModel)
                        }
                    }
                case .error:
                    Text("Error occured")
                    Button("Retry", action: { viewModel.load() })
                }
            }
            .navigationTitle("Invitation")
            .toolbar {
                Button("Logout") { viewModel.logout() }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        InvitationsView(viewModel: InvitationsViewModel(dependencies: Dependencies()))
    }
}

private extension InvitationsViewModel.State {
}
