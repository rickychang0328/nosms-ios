//
//  AppDelegate.swift
//  TWAzureAuthenticator
//
//  Created by 誠帷數位科技 on 2019/11/22.
//

import UIKit

@UIApplicationMain
class AuthenticatorAppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow? = UIWindow(frame: UIScreen.main.bounds)

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let rootVC = TokenListViewController(viewModel: TokenListVCViewModel())
        let firstVC = UINavigationController(rootViewController: rootVC)
        self.window?.rootViewController = firstVC
        self.window?.makeKeyAndVisible()
        
        return true
    }
}
