//
//  AddInvitationView.swift
//  Invi
//
//  Created by Marcin Mucha on 14/11/2021.
//

import SwiftUI
import Combine

@MainActor
class AddInvitationViewModel: Identifiable, ObservableObject {
    typealias Dependencies = HasInviClient

    enum State: Equatable {
        case idle
        case loading
        case error
        case success
    }

    @Published var state: State = .idle
    @Published var code: String = ""
    @Published var validatedCode: Int = 0

    var observations: Set<AnyCancellable> = []
    private var redeemTask: Task<Void, Error>?

    let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies

        $code
            .removeDuplicates()
            .filter { $0.count == 10 }
            .filter { _ in self.state != .loading }
            .compactMap { Int($0) }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] code in
                self?.validatedCode = code
            }
            .store(in: &observations)

        Task { @MainActor in
            for await _ in $code.values where state == .error {
                state = .idle
            }
        }
    }

    func redeem(code: Int) async {
        state = .loading
        redeemTask?.cancel()
        let task = Task {
            try await dependencies.inviClient.redeemInvitation(code)
        }
        redeemTask = task
        switch await task.result {
        case .success:
            state = .success
        case .failure:
            state = .error
        }
    }
}

struct AddInvitationView: View {
    @ObservedObject var viewModel: AddInvitationViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack(spacing: 44) {
            Image(Images.loveLetter)
            VStack {
                Text("Enter invitation code:")
                    .foregroundColor(InviDesign.Colors.Brand.grey)
                    .font(Font.system(size: 12))
                if viewModel.state == .loading {
                    TextField(viewModel.code, text: .constant(""))
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(1)
                        .disabled(true)
                } else {
                    TextField("", text: $viewModel.code)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(1)
                        .keyboardType(.numberPad)
                        .foregroundColor(viewModel.state == .loading ? Color.gray : Color.blue)
                }
            }
            if viewModel.state == .loading {
                ProgressView()
                    .foregroundColor(Color.mint)
            }
            if viewModel.state == .error {
                Text("Error occured. Check your code or try again later.")
                    .foregroundColor(.red)
            }
            Spacer()
        }
        .multilineTextAlignment(.center)
        .padding()
        .onReceive(viewModel.$validatedCode.dropFirst()) { code in
            Task {
                await viewModel.redeem(code: code)
            }
        }
        .onReceive(viewModel.$state) { state in
            if state == .success {
                dismiss()
            }
        }
    }
}

private extension Formatter {
    static var number: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        return formatter
    }
}

struct AddInvitationView_Previews: PreviewProvider {
    static var previews: some View {
        AddInvitationView(viewModel: AddInvitationViewModel(dependencies: CustomDependencies()))
    }
}
