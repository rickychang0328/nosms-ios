
import UIKit
import BiometricAuthentication

@UIApplicationMain
class NoSMSAppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow? = UIWindow(frame: UIScreen.main.bounds)
        
    var authSuccess: (() -> Void)?
    
    static var shared: NoSMSAppDelegate {
        return UIApplication.shared.delegate as! NoSMSAppDelegate
    }
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let rootVC = TokenListViewController(viewModel: TokenListVCViewModel())
        let firstVC = BaseNavigationController(rootViewController: rootVC)
        self.window?.rootViewController = firstVC
        self.window?.makeKeyAndVisible()
        
        //MARK: LaunchScreen 坑
        
        clearLaunchScreenCache()
        
        if AuthIDStatusManager.isAuthOpen {
            
            firstVC.showBlurWithIDAuth(sucessHandler: {
                
                self.authSuccess?()
                self.authSuccess = nil
            }, systemIsNotOpenHandler: nil)
        }
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
                
        if AuthIDStatusManager.isLockWindow {
            
        } else {
            
            PastedAction.shared.applicationDidBecomeActive()
        }
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        
        KeychainTokenStore.shared.appWillEnterForeground()
        
        let nowDate = Date()
        
        if AuthIDStatusManager.isAuthOpen {
            
            if AuthIDStatusManager.isLockWindow {
                
                AuthIDStatusManager.showIDAuthPage(inVC: BlurViewController.shared, sucessHandler: {
                    
                    BlurViewController.shared.dismiss(animated: false, completion: {
                        
                        self.authSuccess?()
                        self.authSuccess = nil
                    })
                })
            } else {
                
                if AuthIDStatusManager.lastInAppTime.timeIntervalSince1970 < nowDate.timeIntervalSince1970 - 300 {
                    
                    self.window?.rootViewController?.getNowWhichVCDisplay().showBlurWithIDAuth(sucessHandler: {
                        
                        self.authSuccess?()
                        self.authSuccess = nil
                    }, systemIsNotOpenHandler: nil)
                }
            }
        }
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        
        print("applicationWillResignActive")
    }

    
    func applicationDidEnterBackground(_ application: UIApplication) {
         print("applicationDidEnterBackground")
         KeychainTokenStore.shared.appDidEnterBackgroundResetting()
         AuthIDStatusManager.backgroundTimerAction()
         PastedAction.shared.applicationDidEnterBackground()
         self.authSuccess = nil
        
    }
    func applicationWillTerminate(_ application: UIApplication) {
         print("applicationWillTerminate")
    }
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        
        PastedAction.shared.applicationIsOpenFromURL()
        
        let thirdAppOpenHandler = { (toastTime: Double) -> Bool in
        
            let action: MustAuth.ActionEnum
            
            let urlComp = URLComponents(string: url.absoluteString) ?? URLComponents()
            
            if let querys = urlComp.queryItems {
                
                let actionQuerys = querys.filter({$0.name == MustAuth.kQueryActionKey})
                
                //超過兩個的action邏輯
                if actionQuerys.count == 1 {
                    
                    guard let actionString = actionQuerys[0].value, let actionEnum = MustAuth.ActionEnum(string: actionString) else {
                        
                        NoSMSHUD.showToast(title: "URL匹配失败")
                        return false
                    }
                    
                    action = actionEnum
                    
                } else if actionQuerys.count == 0 {
                    
                    action = .set
                } else {
                    
                    NoSMSHUD.showToast(title: "URL匹配失败")
                    return false
                }
            } else {
                
                NoSMSHUD.showToast(title: "URL匹配失败")
                return false
            }
            
            guard url.host == MustAuth.factorTimerKey || url.host == MustAuth.factorCounterKey || url.host == nil else {
                
                NoSMSHUD.showToast(title: "URL匹配失败")
                return false
            }
            
            switch action {
                
            case .mulitpleShare:
                
                break
            case .set:
                
                if let token = try? url.absoluteString.mustAuth.parsingSetURL() {
                    
                    let nowVC = self.window?.rootViewController?.getNowWhichVCDisplay()
                    
                    
                    let tokens = KeychainTokenStore.shared.getAllSameTokens(name: token.name, issuer: token.issuer)
                    
                    let saveClosure = { KeychainTokenStore.shared.addTokenWith(urlString: token.url.absoluteString) { event in
                            switch event {
                                
                            case .addSuccess:
                                break
                            case .haveTheSame(let title, let message, let completion):
                                
                                nowVC?.showAlert(title: title, message: message, confirmAction: completion)
                            case .addError:
                                NoSMSHUD.showToast(title: "创建失败")
                            }
                        }
                    }
                    
                    if tokens.count > 0 {
                        
                        saveClosure()
                    } else {
                        
                        nowVC?.showAlert(title: "请确认是否要添加",
                                         message: "[ \(token.issuer) ] \(token.name)",
                            confirmAction: saveClosure)
                    }
                    
                } else {
                    
                    NoSMSHUD.showToast(title: "创建失败")
                    return false
                }
            case .get:
                
                if let token = try? url.mustAuth.parsingGetURL() {
                    
                    let tokens: [AdapterTokenProtocol]
                    
                    //url action get 的條件判斷 totp, hotp, 與空白的可能
                    if let isOntime = token.isOnTime {
                        
                        tokens = KeychainTokenStore.shared.getSameTokensWithType(name: token.name, issuer: token.issuer, isOnTime: isOntime)
                    } else {
                        
                        tokens = KeychainTokenStore.shared.getAllSameTokens(name: token.name, issuer: token.issuer)
                    }
                    
                    if tokens.count == 0 {
                        
                        NoSMSHUD.showToast(title: "未匹配到验证码")
                    } else if tokens.count == 1 {
                        
                        //如果是 hotp 要更新一下
                        if !tokens[0].isOnTime {
                            
                            tokens[0].getOnTapPassword()
                        }
                        UIPasteboard.general.string = tokens[0].token.currentPassword
                        
                        NoSMSHUD.showToast(title: "[ \(token.issuer) ]\n\(token.name)\n验证码已复制")
                    } else {
                        
                        NoSMSHUD.showToast(title: "匹配到多个验证码，请手动复制")
                    }
                } else {
                    
                    NoSMSHUD.showToast(title: "复制失败")
                    return false
                }
            }
            return true
        }

        if AuthIDStatusManager.isAuthOpen {
            
            if AuthIDStatusManager.isLockWindow {

                authSuccess = {
                    
                    _ = thirdAppOpenHandler(3)
                }
            } else {
                
                self.window?.rootViewController?.getNowWhichVCDisplay().showBlurWithIDAuth(sucessHandler: {
                                      
                    _ = thirdAppOpenHandler(3)
                })
            }
            
            return true
        } else {
            
            return thirdAppOpenHandler(2)
        }
    }
    
    func clearLaunchScreenCache() {
        
        do {
            try FileManager.default.removeItem(atPath: NSHomeDirectory()+"/Library/SplashBoard")
        } catch {
            print("Failed to delete launch screen cache: \(error)")
        }
    }
}

extension UIViewController {
    
    func getNowWhichVCDisplay() -> UIViewController {
        
        guard let presentedVC = presentedViewController else {
            
            return self
        }
        return presentedVC.getNowWhichVCDisplay()
    }
}
