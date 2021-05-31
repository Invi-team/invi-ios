//
//  SignInView.swift
//  Invi
//
//  Created by Michal Gorzalczany on 30/05/2021.
//

import SwiftUI

struct SheetView: View {
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            Color.red.edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
            Button("Press to dismiss") {
                presentationMode.wrappedValue.dismiss()
            }
            .font(.title)
            .padding()
            .background(Color.black)
        }
    }
}

struct SignInView: View {

    @State private var showingSheet = false

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
                    signUpButton.onTapGesture {
                        showingSheet.toggle()
                    }
                    .sheet(isPresented: $showingSheet) {
                        SheetView()
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
