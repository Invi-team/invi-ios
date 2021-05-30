//
//  SignInView.swift
//  Invi
//
//  Created by Michal Gorzalczany on 30/05/2021.
//

import SwiftUI

struct SignInView: View {
    var body: some View {
        ZStack {
            InviDesign.Colors.Background.purple.edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
            VStack(alignment: .center) {
                Spacer()
                Image("invi-logo")
                Spacer()
                Image("invi-envelope")
                Spacer()
                Button("Sign in with e-mail") {
                    //
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: InviDesign.Layout.Button.cornerRadius)
                        .fill(InviDesign.Colors.Background.grey)
                        .frame(minWidth: 280)
                )
                .foregroundColor(.white)
                Spacer()
            }
        }
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView()
    }
}
