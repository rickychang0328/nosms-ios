
import UIKit

extension UIView {
    
    @discardableResult
    func addBorder(color: UIColor, width: CGFloat) -> Self {
        
        self.layer.borderWidth = width
        self.layer.borderColor = color.cgColor
        return self
    }
    
    enum THViewMark {
        
        case top
        case bottom
        case left
        case rigth
    }
    
    @discardableResult
    func addBorder(place: THViewMark, width: CGFloat, color: UIColor? = nil) -> Self {
        
        let view = BorderView()
        
        let makeColor: UIColor?
        
        if color == nil {
            
            makeColor = UIColor(cgColor: self.layer.borderColor ?? UIColor.clear.cgColor)
        } else {
            
            makeColor = color
        }
        
        view.backgroundColor = makeColor
        
        addSubview(view)
        view.snp.makeConstraints {
            
            switch place {
                
            case .top:
                
                $0.height.equalTo(width)
                $0.top.right.left.equalToSuperview()
            case .bottom:
                
                $0.height.equalTo(width)
                $0.bottom.right.left.equalToSuperview()
            case .left:
                
                $0.width.equalTo(width)
                $0.bottom.top.left.equalToSuperview()
            case .rigth:
                
                $0.width.equalTo(width)
                $0.bottom.top.right.equalToSuperview()
            }
        }
        
        return self
    }
    
    @discardableResult
    func changeAddBorderColor(color: UIColor) -> Self {
        
        let borderView = subviews.filter({ $0 is BorderView })
        borderView.forEach({ $0.backgroundColor = color })
        
        return self
    }
    
    @discardableResult
    func removeAddBorderView() -> Self {
           
        let borderView = subviews.filter({ $0 is BorderView })
        borderView.forEach({ $0.removeFromSuperview() })
        
        return self
    }
    
    @discardableResult
    func addBorderView(isHide: Bool) -> Self {
           
        let borderView = subviews.filter({ $0 is BorderView })
        borderView.forEach({ $0.isHidden = isHide })
        
        return self
    }

    
    @discardableResult
    func setBackgroundColor(_ color: UIColor) -> Self {
        
        self.backgroundColor = color
        return self
    }
    
    @discardableResult
    func addCornerRadius(at radius: CGFloat) -> Self {
        
        self.layer.masksToBounds = true
        self.layer.cornerRadius = radius
        return self
    }
    
    @discardableResult
    func addCornerAndBorder(backgroundColor: UIColor = UIColor.white,
                            cornerRadius: CGFloat = ScaleWidth(at: 10),
                            masksToBounds: Bool = true,
                            borderColor: UIColor,
                            borderWidth:CGFloat ) {
        
        self.backgroundColor = backgroundColor
        self.layer.cornerRadius = cornerRadius
        self.layer.masksToBounds = masksToBounds
        self.layer.borderColor = borderColor.cgColor
        self.layer.borderWidth = borderWidth
    }
}

private class BorderView: UIView {}
