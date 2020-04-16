
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
        
        BlurViewController.shared.modalPresentationStyle = .overFullScreen
        self.present(BlurViewController.shared, animated: false) {
            
            let sucess = {
                sucessHandler?()
                BlurViewController.shared.dismiss(animated: false)
            }
            
            AuthIDStatusManager.showIDAuthPage(inVC: BlurViewController.shared, sucessHandler: sucess, systemIsNotOpenHandler: systemIsNotOpenHandler)
        }
    }
}

