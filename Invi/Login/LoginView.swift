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
    @Published var state: State = .idle

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
        email = "postman.existing@maildrop.cc"
        password = "apitest1234"
    }

    func handleLogin() {
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
            }, receiveValue: { _ in
                self.state = .loggedIn
            })

    }
}

struct LoginView: View {
    @Environment(\.presentationMode) var presentationMode

    @ObservedObject var viewModel: LoginViewModel

    var body: some View {
        ZStack {
            loadingView
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
                        viewModel.handleLogin()
                    }
                    .buttonStyle(LoginRegisterButtonStyle())
                    Spacer()

                }
                .padding()
            }
        }
        .navigationBarTitle("Sign In", displayMode: .inline)
        .navigationBarItems(trailing: Button("Cancel", action: {
            presentationMode.wrappedValue.dismiss()
        }).foregroundColor(InviDesign.Colors.Brand.dark)
        )
        .onReceive(viewModel.$state) { state in
            if state == .loggedIn {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .disabled(viewModel.state == .evaluating)
    }

    @ViewBuilder var headerText: some View {
        HStack {
            Text("Using Invi for the first time? ")
                .font(Font.system(size: 14))
                .foregroundColor(InviDesign.Colors.Brand.grey)
            Button("Create Account") {
                presentationMode.wrappedValue.dismiss()
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

    @ViewBuilder var loadingView: some View {
        if viewModel.state == .evaluating {
            ZStack {
                Rectangle()
                    .foregroundColor(Color.white)
                    .cornerRadius(8)
                    .frame(width: 100, height: 100, alignment: .center)
                    .shadow(color: .black.opacity(0.16), radius: 12, x: 0, y: 5)
                ActivityIndicator(style: .large)
            }
            .zIndex(1)
        }
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
