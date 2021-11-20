//
//  SettingsView.swift
//  Invi
//
//  Created by Marcin Mucha on 14/11/2021.
//

import SwiftUI
import InviAuthenticator

class SettingsViewModel: ObservableObject {
    typealias Dependencies = HasAuthenticator

    @Published var user: User?

    let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies

        Task { @MainActor in
            for await state in dependencies.authenticator.state.values {
                if case .loggedIn(_, let user) = state {
                    self.user = user
                }
            }
        }
    }

    func logout() {
        dependencies.authenticator.logout()
    }
}

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        NavigationView {
            VStack {
                VStack {
                    Text("Welcome, \(viewModel.user?.email ?? "unkown user")")
                        .padding()
                    Button("Logout") {
                        viewModel.logout()
                    }
                }
            }
        }
        .navigationTitle(Strings.Tab.settings)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(viewModel: SettingsViewModel(dependencies: CustomDependencies()))
    }
}
