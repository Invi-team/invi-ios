//
//  TabView.swift
//  Invi
//
//  Created by Marcin Mucha on 14/11/2021.
//

import SwiftUI

class HomeTabViewModel: ObservableObject {
    typealias Dependencies = InvitationsViewModel.Dependencies & SettingsViewModel.Dependencies

    enum Tab {
        case invitations
        case settings
    }

    @Published var tab: Tab

    let dependencies: Dependencies

    init(tab: Tab = .invitations, dependencies: Dependencies) {
        self.tab = tab
        self.dependencies = dependencies
    }
}

struct HomeTabView: View {
    @ObservedObject var viewModel: HomeTabViewModel

    var body: some View {
        TabView(selection: $viewModel.tab) {
            InvitationsView(viewModel: InvitationsViewModel(dependencies: viewModel.dependencies))
                .tabItem { Label(Strings.Tab.invitations, systemImage: "list.bullet.rectangle") }
                .tag(HomeTabViewModel.Tab.invitations)
            SettingsView(viewModel: SettingsViewModel(dependencies: viewModel.dependencies))
                .tabItem { Label(Strings.Tab.settings, systemImage: "gearshape") }
                .tag(HomeTabViewModel.Tab.settings)
        }
    }
}

struct HomeTabView_Previews: PreviewProvider {
    static var previews: some View {
        HomeTabView(viewModel: HomeTabViewModel(dependencies: CustomDependencies()))
    }
}
