//
//  SignInView.swift
//  Invi
//
//  Created by Marcin Mucha on 09/06/2021.
//

import SwiftUI
import Combine

class LoginViewModel: Identifiable, ObservableObject {
    typealias Dependencies = HasAuthenticator

    @Published var email: String = ""
    @Published var password: String = ""
    @Published var state: State = .idle

    var onDismiss: () -> Void = { assertionFailure("Needs to be set") }
    var onRegister: () -> Void = { assertionFailure("Needs to be set") }

    enum State: Equatable {
        case idle
        case evaluating
        case error(ValidationError)
        case loggedIn

        var isEvaluating: Bool {
            guard case .evaluating = self else { return false }
            return true
        }
    }

    enum ValidationError: Error {
        case invalidCredentials
        case serverFailure
    }

    private let dependencies: Dependencies
    private var cancellables: Set<AnyCancellable> = []
    private var loginCancellable: AnyCancellable?

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
        email = "guest218@invi.click"
        password = "123456"
    }

    func loginTapped() {
        state = .evaluating
        loginCancellable = dependencies.authenticator.login(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    switch error {
                    case .invalidCredentials:
                        self.state = .error(.invalidCredentials)
                    case .other(let error):
                        debugPrint("Login failed with error: \(error)")
                        self.state = .error(.serverFailure)
                    case .notLoggedOut:
                        assertionFailure()
                    }
                }
            }, receiveValue: { [weak self] _ in
                self?.onDismiss()
                self?.state = .loggedIn
            })
    }

    func registerTapped() {
        onRegister()
    }
}

struct LoginView: View {
    @ObservedObject var viewModel: LoginViewModel

    var body: some View {
        ZStack {
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
                    errorText
                    Button("Sign in") {
                        viewModel.loginTapped()
                    }
                    .buttonStyle(LoginRegisterButtonStyle(isLoading: viewModel.state.isEvaluating))
                    Spacer()

                }
                .padding()
            }
        }
        .navigationTitle("Sign in")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Cancel") { viewModel.onDismiss() }
                    .foregroundColor(InviDesign.Colors.Brand.dark)
                    .disabled(viewModel.state == .evaluating)
            }
        }
        .interactiveDismissDisabled(viewModel.state == .evaluating)
    }

    @ViewBuilder var headerText: some View {
        HStack {
            Text("Using Invi for the first time? ")
                .font(Font.system(size: 14))
                .foregroundColor(InviDesign.Colors.Brand.grey)
            Button("Create Account") {
                viewModel.registerTapped()
            }
            .font(Font.system(size: 14).weight(.semibold))
            .foregroundColor(InviDesign.Colors.Brand.dark)
        }
    }

    @ViewBuilder var errorText: some View {
        viewModel.state.errorMessage.flatMap { text in
            Text(text)
                .font(.footnote)
                .foregroundColor(.red)
        }
    }
}

struct LoginRegisterButtonStyle: ButtonStyle {
    var isLoading: Bool

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            if isLoading {
                ProgressView().padding(.trailing)
            }
            configuration.label
        }
        .frame(maxWidth: 350, maxHeight: 30)
        .font(Font.system(size: 16).weight(.bold))
        .padding()
        .background(InviDesign.Colors.Brand.dark)
        .foregroundColor(.white)
        .cornerRadius(8)
    }
}

private extension LoginViewModel.State {
    var errorMessage: String? {
        switch self {
        case .error(.invalidCredentials):
            return "Email or password is incorrect. Try again."
        case .error(.serverFailure):
            return "Something went wrong. Try again."
        default:
            return nil
        }
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(viewModel: LoginViewModel(dependencies: Dependencies()))
    }
}