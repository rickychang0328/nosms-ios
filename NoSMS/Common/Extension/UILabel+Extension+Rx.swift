
import UIKit
import RxSwift
import RxCocoa

extension Reactive where Base: UILabel {
    
    var textColor: Binder<UIColor> {
        
        return Binder(self.base) { label, color in
            
            label.textColor = color
        }
    }
}

