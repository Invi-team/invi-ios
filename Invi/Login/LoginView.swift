//
//  SignInView.swift
//  Invi
//
//  Created by Marcin Mucha on 09/06/2021.
//

import SwiftUI
import Combine

class LoginViewModel: ObservableObject {
    typealias Dependencies = HasAuthenticator

    @Published var email: String = ""
    @Published var password: String = ""
    @Published var shouldDismiss: Bool = false

    enum ValidationError: Error {
        case invalidCredentials
    }

    private let dependencies: Dependencies
    private var cancellables: Set<AnyCancellable> = []

    init(dependencies: Dependencies) {
        self.dependencies = dependencies

        dependencies.authenticator.state.sink { [weak self] state in
            if state == .loggedIn {
                self?.shouldDismiss = true
            }
        }.store(in: &cancellables)

        email = "postman.existing@maildrop.cc"
        password = "apitest1234"
    }

    func handleLogin() {
        dependencies.authenticator.login(email: email, password: password)
    }
}

struct LoginView: View {
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject var viewModel: LoginViewModel

    var body: some View {
        NavigationView {
            VStack {
                VStack(alignment: .leading) {
                    Text("E-mail")
                    TextField("", text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .border(Color.black, width: 1)
                }
                VStack(alignment: .leading) {
                    Text("Password")
                    SecureField("", text: $viewModel.password)
                        .border(Color.black, width: 1)
                }
                Button("Sign in with e-mail") {
                    viewModel.handleLogin()
                }
                Spacer()

            }
            .padding()
        }
        .navigationTitle("Sign in")
        .onReceive(viewModel.$shouldDismiss) { shouldDismiss in
            if shouldDismiss {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(viewModel: LoginViewModel(dependencies: Dependencies()))
    }
}
