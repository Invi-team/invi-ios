//
//  ContentView.swift
//  Invi
//
//  Created by Marcin Mucha on 20/05/2021.
//

import SwiftUI

struct ContentView: View {
    let viewModel: ContentViewModel

    var body: some View {
        VStack {
            Text("You're logged in.")
            Button("Log out") { viewModel.logout() }
        }
    }
}

final class ContentViewModel: ObservableObject {
    typealias Dependencies = HasAuthenticator

    private let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func logout() {
        dependencies.authenticator.logout()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(viewModel: ContentViewModel(dependencies: Dependencies()))
    }
}
