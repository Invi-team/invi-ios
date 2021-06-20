//
//  ActivityIndiator.swift
//  Invi
//
//  Created by Marcin Mucha on 19/06/2021.
//

import SwiftUI
import UIKit

struct ActivityIndicator: UIViewRepresentable {
    let style: UIActivityIndicatorView.Style

    func makeUIView(context: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
        return UIActivityIndicatorView(style: style)
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<ActivityIndicator>) {
        uiView.isHidden = false
        uiView.startAnimating()
    }
}
