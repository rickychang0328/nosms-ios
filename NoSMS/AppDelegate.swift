
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
        
        KeychainTokenStore.shared.appWillEnterForeground()
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        
        print("applicationWillResignActive")
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        
        KeychainTokenStore.shared.appDidEnterBackgroundResetting()
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
                
        PastedAction.shared.applicationIsOpenFromURL()
        
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
            
        case .set:
            
            if let token = try? url.absoluteString.mustAuth.parsingSetURL() {
                
                let nowVC = window?.rootViewController?.getNowWhichVCDisplay()

                
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
                    UIPasteboard.general.string = try? tokens[0].password.value()
                    
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
}

extension UIViewController {
    
    func getNowWhichVCDisplay() -> UIViewController {
        
        guard let presentedVC = presentedViewController else {
            
            return self
        }
        return presentedVC.getNowWhichVCDisplay()
    }
}
