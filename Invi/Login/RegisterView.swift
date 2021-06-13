//
//  SignUpView.swift
//  Invi
//
//  Created by Marcin Mucha on 06/06/2021.
//

import SwiftUI
import Combine

class RegisterViewModel: ObservableObject {
    typealias Dependencies = HasAuthenticator

    @Published var email: String = ""
    @Published var password: String = ""
    @Published var repeatedPassword: String = ""
    @Published var shouldDismiss: Bool = false

    var emailValidationResult: Result<Void, ValidationError> = .failure(.empty)
    var passwordValidationResult: Result<Void, ValidationError> = .failure(.empty)

    enum ValidationError: Error {
        case invalidEmail
        case passwordTooShort
        case passwordIncorrectlyRepeated
        case empty
        // TODO: Think about more cases re: credentials
    }

    private let dependencies: Dependencies
    private var cancellables: Set<AnyCancellable> = []
    private var registerCancellable: AnyCancellable?

    init(dependencies: Dependencies) {
        self.dependencies = dependencies

        $email
            .sink { [unowned self] emailValue in
                if emailValue.contains("@") {
                    self.emailValidationResult = .success(())
                } else {
                    self.emailValidationResult = .failure(.invalidEmail)
                }
            }
            .store(in: &cancellables)

        $password
            .sink { [unowned self] passwordValue in
                if !passwordValue.isEmpty {
                    self.passwordValidationResult = .success(())
                } else {
                    self.passwordValidationResult = .failure(.passwordTooShort)
                }
            }
            .store(in: &cancellables)

        $repeatedPassword
            .sink { [unowned self] passwordValue in
                if passwordValue == password {
                    self.passwordValidationResult = .success(())
                } else {
                    self.passwordValidationResult = .failure(.passwordIncorrectlyRepeated)
                }
            }
            .store(in: &cancellables)

        dependencies.authenticator.state.sink { [weak self] state in
            if state == .loggedIn {
                self?.shouldDismiss = true
            }
        }.store(in: &cancellables)
    }

    func handleRegister() {
        switch (emailValidationResult, passwordValidationResult) {
        case (.success, .success):
            print("Email: \(email), password: \(password)")
            registerCancellable = dependencies.authenticator.register(email: email, password: password)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        print("Registration failed with error: \(error)")
                    case .finished:
                        break
                    }
                }, receiveValue: { [weak self] _ in
                    self?.shouldDismiss = true
                })
        default:
            print("Invalid format of email or passowrd")
        }
    }
}

struct RegisterView: View {
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject var viewModel: RegisterViewModel

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
                        .padding(.bottom, 16)
                }
                VStack(alignment: .leading) {
                    Text("Repeat Password")
                        .foregroundColor(InviDesign.Colors.Brand.grey)
                        .font(Font.system(size: 12))
                    SecureField("", text: $viewModel.repeatedPassword)
                    Divider()
                        .background(InviDesign.Colors.Background.grey)
                        .frame(height: 2)
                        .padding(.bottom, 24)
                }
                Button("Sign up with e-mail") {
                    viewModel.handleRegister()
                }
                .buttonStyle(LoginRegisterButtonStyle())
                Spacer()
                
            }
            .padding()
        }
        .navigationBarTitle("Sign up", displayMode: .inline)
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
        Text("Already have account? ")
            .font(Font.system(size: 14))
            .foregroundColor(InviDesign.Colors.Brand.grey)
        +
        Text("Sign in")
            .font(Font.system(size: 14).weight(.semibold))
            .foregroundColor(InviDesign.Colors.Brand.dark)
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView(viewModel: RegisterViewModel(dependencies: Dependencies())) // TODO: Use some mock
    }
}
