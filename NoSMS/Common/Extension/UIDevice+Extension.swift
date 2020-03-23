
import UIKit

extension UIDevice {
    
    static var isOniOS13UpDarkMode: Bool {
        
        if #available(iOS 13, *), UITraitCollection.current.userInterfaceStyle == .dark {
            
            return true
        } else {
            
            return false
        }
    }
}
