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
        VStack {
            VStack(alignment: .leading) {
                headerText
                    .padding(.bottom, 24)
                VStack(alignment: .leading) {
                    Text("E-mail")
                        .foregroundColor(InviDesign.Colors.Brand.grey)
                        .font(Font.system(size: 12))
                    TextField("", text: $viewModel.email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    Divider()
                        .background(InviDesign.Colors.Background.grey)
                        .frame(height: 2)
                        .padding(.bottom, 16)
                }
                VStack(alignment: .leading) {
                    Text("Password")
                        .foregroundColor(InviDesign.Colors.Brand.grey)
                        .font(Font.system(size: 12))
                    SecureField("", text: $viewModel.password)
                    Divider()
                        .background(InviDesign.Colors.Background.grey)
                        .frame(height: 2)
                        .padding(.bottom, 24)
                }
                Button("Sign in") {
                    viewModel.handleLogin()
                }
                .buttonStyle(LoginRegisterButtonStyle())
                Spacer()

            }
            .padding()
        }
        .navigationBarTitle("Sign In", displayMode: .inline)
        .navigationBarItems(trailing: Button("Cancel", action: {
            presentationMode.wrappedValue.dismiss()
        }).foregroundColor(InviDesign.Colors.Brand.dark)
        )
        .onReceive(viewModel.$shouldDismiss) { shouldDismiss in
            if shouldDismiss {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }

    @ViewBuilder var headerText: Text {
        Text("Using Invi for the first time? ")
            .font(Font.system(size: 14))
            .foregroundColor(InviDesign.Colors.Brand.grey)
        +
        Text("Create Account")
            .font(Font.system(size: 14).weight(.semibold))
            .foregroundColor(InviDesign.Colors.Brand.dark)
    }
}

struct LoginRegisterButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: 350, maxHeight: 30)
            .font(Font.system(size: 16).weight(.bold))
            .padding()
            .background(InviDesign.Colors.Brand.dark)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(viewModel: LoginViewModel(dependencies: Dependencies()))
    }
}
