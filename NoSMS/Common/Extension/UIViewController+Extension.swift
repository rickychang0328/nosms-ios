
import UIKit
import BiometricAuthentication

extension UIViewController {
    
    func showErrorAlert(title: String? = nil, message: String? = nil, cancelTitle: String = "ok", alertCompletionHandler: @escaping () -> Void = {}) {
        
        let view = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let cancelAlertAction = UIAlertAction(title: cancelTitle, style: .cancel) { [weak view] _ in
            
            view?.dismiss(animated: true, completion: alertCompletionHandler)
        }
        
        view.addAction(cancelAlertAction)
        
        present(view, animated: true, completion: nil)
    }
        
    func showBlurWithIDAuth(sucessHandler: (() -> Void)? = nil, systemIsNotOpenHandler: (() -> Void)? = nil) {
        AuthIDStatusManager.isLockWindow = true
        BlurViewController.shared.modalPresentationStyle = .overFullScreen
        self.present(BlurViewController.shared, animated: false) {
            
            let sucess = {
                BlurViewController.shared.dismiss(animated: false, completion: sucessHandler)
            }
            
            AuthIDStatusManager.showIDAuthPage(inVC: BlurViewController.shared, sucessHandler: sucess, systemIsNotOpenHandler: systemIsNotOpenHandler)
        }
    }
    
    func showSettingAppAuthPage() {
        
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            
            UIApplication.shared.open(settingsUrl, completionHandler: nil)
        }
    }
    
    func showAlertToOpenSettingURL(title: String?, message: String?) {
        
        let alertController = UIAlertController (title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "确认", style: .default, handler: nil)
        alertController.addAction(cancelAction)
        let settingsAction = UIAlertAction(title: "设定", style: .default) { _ in
            
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            
            if UIApplication.shared.canOpenURL(settingsUrl) {
                
                UIApplication.shared.open(settingsUrl, completionHandler: nil)
            }
        }
        alertController.addAction(settingsAction)
        
        self.present(alertController, animated: true, completion: nil)
    }

}

