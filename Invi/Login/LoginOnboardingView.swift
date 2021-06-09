//
//  SignInView.swift
//  Invi
//
//  Created by Michal Gorzalczany on 30/05/2021.
//

import SwiftUI

struct LoginOnboardingView: View {
    typealias Dependencies = RegisterViewModel.Dependencies & LoginViewModel.Dependencies

    @State private var showingSignInSheet = false
    @State private var showingSignUpSheet = false

    let dependencies: Dependencies

    var body: some View {
        NavigationView {
            ZStack {
                InviDesign.Colors.Brand.light.edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
                VStack(alignment: .center) {
                    Image("invi-logo")
                    Spacer()
                    Image("invi-envelope")
                    Spacer()
                    Button("Sign in with e-mail") {
                        showingSignInSheet.toggle()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: InviDesign.Layout.Button.cornerRadius)
                            .fill(InviDesign.Colors.Background.grey)
                            .frame(minWidth: 280)
                    )
                    .foregroundColor(.white)
                    .sheet(isPresented: $showingSignInSheet) {
                        LoginView(viewModel: LoginViewModel(dependencies: dependencies))
                    }
                    Spacer()
                    signUpButton.onTapGesture {
                        showingSignUpSheet.toggle()
                    }
                    .sheet(isPresented: $showingSignUpSheet) {
                        RegisterView(viewModel: RegisterViewModel(dependencies: dependencies))
                    }
                }
                .padding(.bottom)
            }
        }
        .background(Color.black)
        .navigationTitle("Invi")
    }

    @ViewBuilder var signUpButton: some View {
        Text("You don't have an account.")
            .foregroundColor(Color(.white))
            +
            Text(" Sign up")
            .foregroundColor(InviDesign.Colors.Brand.dark)
    }
}
