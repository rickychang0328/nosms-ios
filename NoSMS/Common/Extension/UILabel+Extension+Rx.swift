
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


extension Reactive where Base: UITableView {
    
    var isEditing: Binder<Bool> {
        
        return Binder<Bool>(self.base) { view, isEdit in
            
            view.isEditing = isEdit
        }
    }
}
