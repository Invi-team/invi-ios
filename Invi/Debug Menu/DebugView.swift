//
//  DebugView.swift
//  Invi
//
//  Created by Marcin Mucha on 05/12/2021.
//

import Foundation
import SwiftUI

struct DebugView: View {
    @ObservedObject var viewModel: DebugViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            List {
                ForEach(viewModel.items) { item in
                    switch item.kind {
                    case .booleanValue(let key):
                        DebugBooleanRowView(viewModel: DebugBooleanRowViewModel(
                            item: item,
                            key: key,
                            dependencies: viewModel.dependencies)
                        )
                    }
                }
            }
            .navigationTitle("Debug menu")
            .toolbar {
                ToolbarItem {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

class DebugBooleanRowViewModel: ObservableObject {
    typealias Dependencies = HasUserDefaults

    @Published var isOn: Bool

    let item: DebugMenuItem

    private let dependencies: Dependencies

    init(item: DebugMenuItem, key: UserDefaultName, dependencies: Dependencies) {
        self.item = item
        self.dependencies = dependencies

        isOn = dependencies.userDefaults.bool(forKey: key) ?? false

        Task { @MainActor in
            for await isEnabled in $isOn.eraseToAnyPublisher().values {
                dependencies.userDefaults.set(bool: isEnabled, forKey: key)
            }
        }
    }
}

struct DebugBooleanRowView: View {
    @ObservedObject var viewModel: DebugBooleanRowViewModel

    var body: some View {
        Toggle(viewModel.item.title, isOn: $viewModel.isOn)
    }
}
