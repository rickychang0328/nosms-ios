
import UIKit

extension UILabel {
    
    @discardableResult
    func setText(_ text: String?) -> Self {
        
        self.text = text
        return self
    }
    
    @discardableResult
    func setFont(_ font: UIFont) -> Self {
        
        self.font = font
        return self
    }
    
    @discardableResult
    func setTextColor(_ color: UIColor) -> Self {
        
        self.textColor = color
        return self
    }
    
    @discardableResult
    func setAttributedText(_ text: NSAttributedString) -> Self {
        self.attributedText = text
        return self
    }
    
    @discardableResult
    func setTextAlignment(_ alignment: NSTextAlignment) -> Self {
        
        self.textAlignment = alignment
        return self
    }
    
    @discardableResult
    func setNumberOfLine(_ number: Int) -> Self {
        
        self.numberOfLines = number
        return self
    }
}
