//
//  Application.swift
//  Invi
//
//  Created by Jakub Kwiatek on 24/11/2021.
//

import Foundation
import UIKit

struct Application {
    let canOpenUrl: (URL) -> Bool = { url in
        UIApplication.shared.canOpenURL(url)
    }
    let openUrl: (URL) -> Void = { url in
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}