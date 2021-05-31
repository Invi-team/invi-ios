//
//  SignInView.swift
//  Invi
//
//  Created by Michal Gorzalczany on 30/05/2021.
//

import SwiftUI

struct SignInView: View {
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
                        Button("Sign in with e-mail") {}
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: InviDesign.Layout.Button.cornerRadius)
                                .fill(InviDesign.Colors.Background.grey)
                                .frame(minWidth: 280)
                        )
                        .foregroundColor(.white)
                    }
                    Spacer()
                    NavigationLink(destination: ContentView()) {
                        signUpButton
                    }
                }
                .padding(.bottom)
            }
        }
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
