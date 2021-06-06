//
//  SignUpView.swift
//  Invi
//
//  Created by Marcin Mucha on 06/06/2021.
//

import SwiftUI
import Combine

class SignUpViewModel: ObservableObject {
    typealias Dependencies = HasAuthenticator

    @Published var email: String = ""
    @Published var password: String = ""

    var emailValidationResult: Result<Void, ValidationError> = .failure(.empty)
    var passwordValidationResult: Result<Void, ValidationError> = .failure(.empty)

    enum ValidationError: Error {
        case invalidEmail
        case passwordTooShort
        case passwordMissingSpecialCharacter
        case empty
        // TODO: Think about more cases re: credentials
    }

    private let dependencies: Dependencies
    private var cancellables: Set<AnyCancellable> = []

    init(dependencies: Dependencies) {
        self.dependencies = dependencies

        $email
            .print()
            .sink { [unowned self] emailValue in
                if emailValue.contains("@") {
                    self.emailValidationResult = .success(())
                } else {
                    self.emailValidationResult = .failure(.invalidEmail)
                }
            }
            .store(in: &cancellables)

        $password
            .print()
            .sink { [unowned self] passwordValue in
                if passwordValue.count > 3 {
                    self.passwordValidationResult = .success(())
                } else {
                    self.passwordValidationResult = .failure(.passwordTooShort)
                }
            }
            .store(in: &cancellables)
    }

    func handleSignUp() {
        switch (emailValidationResult, passwordValidationResult) {
        case (.success, .success):
            print("Email: \(email), password: \(password)")
            dependencies.authenticator.login(email: email, password: password)
        default:
            print("Invalid format of email or passowrd")
        }
    }
}

struct SignUpView: View {
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject var viewModel: SignUpViewModel

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
                    viewModel.handleSignUp()
                }
                Spacer()
                
            }
            .padding()
        }
        .navigationTitle("Sign in")
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView(viewModel: SignUpViewModel(dependencies: Dependencies())) // TODO: Use some mock
    }
}
