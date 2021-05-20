//
//  SceneDelegate.swift
//  Invi
//
//  Created by Marcin Mucha on 20/05/2021.
//

import UIKit
import SwiftUI

private var inviDependencies: InviDependencies!

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        let contentView = ContentView()
        if let windowScene = scene as? UIWindowScene {
            let window = UIWindow(windowScene: windowScene)
            window.rootViewController = UIHostingController(rootView: contentView)
            self.window = window
            window.makeKeyAndVisible()
        }
    }
}

func inviMain(dependencies: @autoclosure () -> InviDependencies) {
    inviDependencies = dependencies()

//    let appDelegateClass = isUnitTesting ? TestDelegate.self : AppDelegate.self TODO
    let appDelegateClass = AppDelegate.self
    _ = UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, NSStringFromClass(UIApplication.self), NSStringFromClass(appDelegateClass))
}

