//
//  AppDelegate.swift
//  TWAzureAuthenticator
//
//  Created by 誠帷數位科技 on 2019/11/22.
//

import UIKit

@UIApplicationMain
class NoSMSAppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow? = UIWindow(frame: UIScreen.main.bounds)

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let rootVC = TokenListViewController(viewModel: TokenListVCViewModel())
        let firstVC = UINavigationController(rootViewController: rootVC)
        self.window?.rootViewController = firstVC
        self.window?.makeKeyAndVisible()
        
        if #available(iOS 13, *) {
            self.window?.overrideUserInterfaceStyle = .light
        }
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        
        PastedAction.shared.applicationDidBecomeActive()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        
        print("applicationWillEnterForeground")
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        
        print("applicationWillResignActive")
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        
        KeychainTokenStore.shared.appDidEnterBackgroundResetting()
    }
    
//    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
//
//    }
    
    
}
