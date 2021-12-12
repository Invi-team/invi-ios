//
//  SignUpView.swift
//  Invi
//
//  Created by Marcin Mucha on 06/06/2021.
//

import SwiftUI
import Combine
import CasePaths
import WebService
import InviAuthenticator

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

    @Published var emailValidationResult: Result<Void, EmailValidationError>?
    @Published var passwordValidationResult: Result<Void, PasswordValidationError>?
    @Published var repeatedPasswordValidationResult: Result<Void, RepeatedPasswordValidationError>?
    @Published var requestError: Error?

    enum EmailValidationError: Error {
        case invalidFormat
        case alreadyUsed
    }

    enum PasswordValidationError: Error {
        case passwordTooShort
    }

    enum RepeatedPasswordValidationError: Error {
        case incorrectlyRepeated
    }

    private let dependencies: Dependencies
    private var cancellables: Set<AnyCancellable> = []
    private var registerCancellable: AnyCancellable?
    private var takenEmail: String?

    init(dependencies: Dependencies) {
        self.dependencies = dependencies

        $email.filter { !$0.isEmpty }
            .sink { [unowned self] _ in
                self.takenEmail = nil
                self.validateEmail(showFailure: false)
            }
            .store(in: &cancellables)

        $password.filter { !$0.isEmpty }
            .sink { [unowned self] _ in
                self.validatePassword(showFailure: true)
            }
            .store(in: &cancellables)

        $repeatedPassword.filter { !$0.isEmpty }
            .sink { [unowned self] _ in
                self.validateRepeatedPassword(showFailure: true)
            }
            .store(in: &cancellables)
    }

    @MainActor
    func handleRegister() async {
        guard !isLoading else { return }
        switch (emailValidationResult, passwordValidationResult, repeatedPasswordValidationResult) {
        case (.success, .success, .success):
            print("Email: \(email), password: \(password)")
            isLoading = true
            do {
                try await dependencies.authenticator.register(email, password)
                isLoading = false
                setSuccessfulNavigation(isActive: true)
            } catch {
                isLoading = false
                debugPrint(error)
                guard let error = error as? Authenticator.RegisterError else {
                    assertionFailure("Incorrect Authenticator error implementation")
                    return
                }
                switch error {
                case .passwordTooShort:
                    passwordValidationResult = .failure(.passwordTooShort)
                case .emailInvalid:
                    emailValidationResult = .failure(.invalidFormat)
                case .emailAlreadyTaken:
                    takenEmail = email
                    emailValidationResult = .failure(.alreadyUsed)
                case .other(let otherError):
                    requestError = otherError
                }
            }
        default:
            validateEmail(showFailure: true)
            validatePassword(showFailure: true)
            validateRepeatedPassword(showFailure: true)
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

    private func validateEmail(showFailure: Bool) {
        if email == takenEmail, case .some(.failure(.alreadyUsed)) = emailValidationResult {
            return
        }
        let emailPattern = #"^\S+@\S+\.\S+$"#
        let isEmailValid = email.range(of: emailPattern, options: .regularExpression) != nil
        if isEmailValid {
            emailValidationResult = .success(())
        } else if showFailure {
            emailValidationResult = .failure(.invalidFormat)
        }
    }

    private func validatePassword(showFailure: Bool) {
        if password.trimmingCharacters(in: .whitespacesAndNewlines).count >= 6 {
            passwordValidationResult = .success(())
        } else if showFailure {
            passwordValidationResult = .failure(.passwordTooShort)
        }
    }

    private func validateRepeatedPassword(showFailure: Bool) {
        if repeatedPassword == password, !password.isEmpty {
            repeatedPasswordValidationResult = .success(())
        } else if showFailure {
            repeatedPasswordValidationResult = .failure(.incorrectlyRepeated)
        }
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
                    emailErrorText
                        .font(.footnote)
                        .foregroundColor(.red)
                }
                .padding(.bottom, 16)
                VStack(alignment: .leading) {
                    Text("Password")
                        .foregroundColor(InviDesign.Colors.Brand.grey)
                        .font(Font.system(size: 12))
                    SecureField("", text: $viewModel.password)
                    Divider()
                        .background(InviDesign.Colors.Background.grey)
                        .frame(height: 2)
                    passwordErrorText
                        .font(.footnote)
                        .foregroundColor(.red)
                }
                .padding(.bottom, 16)
                VStack(alignment: .leading) {
                    Text("Repeat Password")
                        .foregroundColor(InviDesign.Colors.Brand.grey)
                        .font(Font.system(size: 12))
                    SecureField("", text: $viewModel.repeatedPassword)
                    Divider()
                        .background(InviDesign.Colors.Background.grey)
                        .frame(height: 2)
                    repeatedPasswordErrorText
                        .font(.footnote)
                        .foregroundColor(.red)
                }
                .padding(.bottom, 16)
                requestErrorText
                    .font(.footnote)
                    .foregroundColor(.red)
                Button("Sign up with e-mail") {
                    Task { @MainActor in
                        await viewModel.handleRegister()
                    }
                }
                .buttonStyle(LoginRegisterButtonStyle(isLoading: viewModel.isLoading))
                .padding(.top, 8)
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

    @ViewBuilder var requestErrorText: some View {
        viewModel.requestError.flatMap { _ in
            Text("Something went wrong. Try again later.")
        }
    }

    @ViewBuilder var emailErrorText: some View {
        switch viewModel.emailValidationResult {
        case .some(.success), .none:
            EmptyView()
        case .some(.failure(.invalidFormat)):
            Text("Please enter a correct e-mail.")
        case .some(.failure(.alreadyUsed)):
            Text("This e-mail is already in use. Choose another one.")
        }
    }

    @ViewBuilder var passwordErrorText: some View {
        switch viewModel.passwordValidationResult {
        case .some(.success), .none:
            EmptyView()
        case .some(.failure(.passwordTooShort)):
            Text("Password needs to have 6 or more characters.")
        }
    }

    @ViewBuilder var repeatedPasswordErrorText: some View {
        switch viewModel.repeatedPasswordValidationResult {
        case .some(.success), .none:
            EmptyView()
        case .some(.failure(.incorrectlyRepeated)):
            Text("Repeated password does not match.")
        }
    }

    private var isRegisterButtonEnabled: Bool {
        switch (viewModel.emailValidationResult, viewModel.passwordValidationResult, viewModel.repeatedPasswordValidationResult) {
        case (.success, .success, .success):
            return true
        default:
            return false
        }
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView(viewModel: RegisterViewModel(dependencies: CustomDependencies()))
    }
}
