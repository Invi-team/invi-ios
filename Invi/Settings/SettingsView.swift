//
//  SettingsView.swift
//  Invi
//
//  Created by Marcin Mucha on 14/11/2021.
//

import SwiftUI

class SettingsViewModel: ObservableObject {
    typealias Dependencies = HasAuthenticator

    let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func logout() {
        dependencies.authenticator.logout()
    }
}

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        NavigationView {
            Button("Logout") {
                viewModel.logout()
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
