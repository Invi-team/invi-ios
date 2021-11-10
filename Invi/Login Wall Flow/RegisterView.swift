//
//  SignUpView.swift
//  Invi
//
//  Created by Marcin Mucha on 06/06/2021.
//

import SwiftUI
import Combine
import CasePaths

class RegisterViewModel: Identifiable, ObservableObject {
    typealias Dependencies = HasAuthenticator

    @Published var email: String = ""
    @Published var password: String = ""
    @Published var repeatedPassword: String = ""
    @Published var isLoading: Bool = false

    @Published var route: Route?

    enum Route {
        case registerSuccessful(RegisterSuccessfulViewModel)
    }

    var onLogin: () -> Void = { assertionFailure("Needs to be set") }
    var onDismiss: () -> Void = { assertionFailure("Needs to be set") }

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
    }

    func handleRegister() async {
        switch (emailValidationResult, passwordValidationResult) {
        case (.success, .success):
            print("Email: \(email), password: \(password)")
            isLoading = true
            do {
                try await dependencies.authenticator.register(email: email, password: password)
                isLoading = false
                setSuccessfulNavigation(isActive: true)
            } catch {
                print("Registration failed with error: \(error)")
                isLoading = false
            }
        default:
            print("Invalid format of email or passowrd")
        }
    }

    func setSuccessfulNavigation(isActive: Bool) {
        guard isActive else { return } // We don't allow going back b/c of the nature of the screen
        let viewModel = RegisterSuccessfulViewModel()
        viewModel.onConfirm = { [weak self] in
            self?.onLogin()
        }
        viewModel.onDismiss = { [weak self] in
            self?.onDismiss()
        }
        route = .registerSuccessful(viewModel)
    }
}

struct RegisterView: View {
    @ObservedObject var viewModel: RegisterViewModel

    var body: some View {
        VStack {
            NavigationLink(
                unwrap: $viewModel.route,
                case: /RegisterViewModel.Route.registerSuccessful,
                onNavigate: viewModel.setSuccessfulNavigation(isActive:),
                destination: { viewModel in RegisterSuccessfulView(viewModel: viewModel.wrappedValue) },
                label: { EmptyView() }
            )
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
                    Task { @MainActor in
                        await viewModel.handleRegister()
                    }
                }
                .buttonStyle(LoginRegisterButtonStyle(isLoading: viewModel.isLoading))
                Spacer()
                
            }
            .padding()
        }
        .navigationTitle("Sign up")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Cancel") { viewModel.onDismiss() }
                    .foregroundColor(InviDesign.Colors.Brand.dark)
                    .disabled(viewModel.isLoading)
            }
        }
        .interactiveDismissDisabled(viewModel.isLoading)
    }

    @ViewBuilder var headerText: some View {
        HStack {
            Text("Already have account? ")
                .font(Font.system(size: 14))
                .foregroundColor(InviDesign.Colors.Brand.grey)
            Button("Sign in") {
                viewModel.onLogin()
            }
            .font(Font.system(size: 14).weight(.semibold))
            .foregroundColor(InviDesign.Colors.Brand.dark)
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView(viewModel: RegisterViewModel(dependencies: Dependencies())) // TODO: Use some mock
    }
}
