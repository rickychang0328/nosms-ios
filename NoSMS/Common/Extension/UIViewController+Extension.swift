//
//  UIViewController+Extension.swift
//  TWAzureAuthenticator
//
//  Created by 誠帷數位科技 on 2019/11/28.
//

import UIKit

extension UIViewController {
    
    func showErrorAlert(title: String? = nil, message: String? = nil, cancelTitle: String = "ok", alertCompletionHandler: @escaping () -> Void = {}) {
        
        let view = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let cancelAlertAction = UIAlertAction(title: cancelTitle, style: .cancel) { [weak view] _ in
            
            view?.dismiss(animated: true, completion: alertCompletionHandler)
        }
        
        view.addAction(cancelAlertAction)
        
        present(view, animated: true, completion: nil)
    }
}

