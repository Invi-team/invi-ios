//
//  SignInView.swift
//  Invi
//
//  Created by Michal Gorzalczany on 30/05/2021.
//

import SwiftUI

struct SignInView: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            Color.yellow.edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
            Button("Press to dismiss") {
                presentationMode.wrappedValue.dismiss()
            }
            .font(.title)
            .padding()
            .background(Color.black)
        }
    }
}

struct LoginOnboardingView: View {
    typealias Dependencies = SignUpViewModel.Dependencies

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
                    NavigationLink(destination: ContentView()) {
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
                            SignInView()
                        }
                    }
                    Spacer()
                    signUpButton.onTapGesture {
                        showingSignUpSheet.toggle()
                    }
                    .sheet(isPresented: $showingSignUpSheet) {
                        SignUpView(viewModel: SignUpViewModel(dependencies: dependencies))
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

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView()
    }
}
