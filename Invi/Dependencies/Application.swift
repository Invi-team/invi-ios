//
//  Application.swift
//  Invi
//
//  Created by Jakub Kwiatek on 24/11/2021.
//

import Foundation
import UIKit

struct Application {
    var canOpenUrl: (URL) -> Bool = { url in
        UIApplication.shared.canOpenURL(url)
    }
    var openUrl: (URL) -> Void = { url in
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    static let live = Application(
        canOpenUrl: { url in
            UIApplication.shared.canOpenURL(url)
        },
        openUrl: { url in
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    )
}
