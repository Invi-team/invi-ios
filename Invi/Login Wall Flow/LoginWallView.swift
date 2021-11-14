//
//  SignInView.swift
//  Invi
//
//  Created by Michal Gorzalczany on 30/05/2021.
//

import SwiftUI
import CasePaths

class LoginWallViewModel: ObservableObject {
    typealias Dependencies = RegisterViewModel.Dependencies & LoginViewModel.Dependencies

    enum Route {
        case login(LoginViewModel)
        case register(RegisterViewModel)
    }

    @Published var route: Route?

    private let dependencies: Dependencies

    init(route: Route? = nil, dependencies: Dependencies) {
        self.route = route
        self.dependencies = dependencies
    }

    private func bind(route: Route?) {
        guard let route = route else { return }
        switch route {
        case .login(let loginViewModel):
            loginViewModel.onDismiss = { [weak self] in
                self?.cancelLoginTapped()
            }
            loginViewModel.onRegister = { [weak self] in
                self?.registerTapped()
            }
        case .register(let registerViewModel):
            registerViewModel.onDismiss = { [weak self] in
                self?.cancelLoginTapped()
            }
            registerViewModel.onLogin = { [weak self] in
                self?.loginTapped()
            }
        }
    }

    func loginTapped() {
        let loginViewModel = LoginViewModel(dependencies: dependencies)
        let loginRoute: Route = .login(loginViewModel)
        bind(route: loginRoute)
        route = loginRoute
    }

    func registerTapped() {
        let registerViewModel = RegisterViewModel(dependencies: dependencies)
        let registerRoute: Route = .register(registerViewModel)
        bind(route: registerRoute)
        route = registerRoute
    }

    func cancelLoginTapped() {
        route = nil
    }
}

struct LoginWallView: View {
    @ObservedObject var viewModel: LoginWallViewModel

    var body: some View {
        NavigationView {
            ZStack {
                InviDesign.Colors.Brand.light.edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
                VStack(alignment: .center) {
                    Image(Images.inviLogo)
                    Spacer()
                    Image(Images.inviEnvelope)
                    Spacer()
                    Button("Sign in with e-mail") {
                        viewModel.loginTapped()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: InviDesign.Layout.Button.cornerRadius)
                            .fill(InviDesign.Colors.Background.grey)
                            .frame(minWidth: 280)
                    )
                    .foregroundColor(.white)
                    .sheet(unwrap: $viewModel.route, case: /LoginWallViewModel.Route.login) { viewModel in
                        NavigationView {
                            LoginView(viewModel: viewModel.wrappedValue)
                        }
                    }
                    Spacer()
                    signUpButton.onTapGesture {
                        viewModel.registerTapped()
                    }
                    .sheet(unwrap: $viewModel.route, case: /LoginWallViewModel.Route.register) { viewModel in
                        NavigationView {
                            RegisterView(viewModel: viewModel.wrappedValue)
                        }
                    }
                }
                .padding(.bottom)
            }
        }
        .background(Color.black)
        .navigationTitle("Invi")
    }

    @ViewBuilder var signUpButton: some View {
        Text("You don't have an account?")
            .foregroundColor(Color(.white))
            +
            Text(" Sign up")
            .foregroundColor(InviDesign.Colors.Brand.dark)
    }
}
