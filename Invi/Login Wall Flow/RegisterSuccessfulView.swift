//
//  RegisterSuccessfulView.swift
//  Invi
//
//  Created by Marcin Mucha on 07/11/2021.
//

import Foundation
import SwiftUI

class RegisterSuccessfulViewModel: Identifiable, ObservableObject {
    var onConfirm: () -> Void = { assertionFailure("Needs to be set") }
    var onDismiss: () -> Void = { assertionFailure("Needs to be set") }
}

struct RegisterSuccessfulView: View {
    @ObservedObject var viewModel: RegisterSuccessfulViewModel

    var body: some View {
        VStack {
            Text("Your account was created.")
                .font(.title2)
            Spacer()
            Image(systemName: "person.crop.circle.fill.badge.checkmark")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.green)
                .frame(width: 200)
            Spacer()
            Button("Login with the account") {
                viewModel.onConfirm()
            }
            .buttonStyle(LoginRegisterButtonStyle(isLoading: false))
            Button("Go back") {
                viewModel.onDismiss()
            }
            .buttonStyle(.borderless)
            .padding(.top)
            Spacer()
        }
        .padding()
        .navigationBarBackButtonHidden(true)
    }
}

struct RegisterSuccessfulView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterSuccessfulView(viewModel: RegisterSuccessfulViewModel())
    }
}
