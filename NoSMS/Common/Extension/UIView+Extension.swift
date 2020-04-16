
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

extension UIView {
    
    // retrieves all constraints that mention the view
    func getAllConstraints() -> [NSLayoutConstraint] {

        // array will contain self and all superviews
        var views = [self]

        // get all superviews
        var view = self
        while let superview = view.superview {
            views.append(superview)
            view = superview
        }

        // transform views to constraints and filter only those
        // constraints that include the view itself
        return views.flatMap({ $0.constraints }).filter { constraint in
            return constraint.firstItem as? UIView == self ||
                constraint.secondItem as? UIView == self
        }
    }

    // Example 1: Get all width constraints involving this view
    // We could have multiple constraints involving width, e.g.:
    // - two different width constraints with the exact same value
    // - this view's width equal to another view's width
    // - another view's height equal to this view's width (this view mentioned 2nd)
    func getWidthConstraints() -> [NSLayoutConstraint] {
        return getAllConstraints().filter( {
            ($0.firstAttribute == .width && $0.firstItem as? UIView == self) ||
            ($0.secondAttribute == .width && $0.secondItem as? UIView == self)
        } )
    }

    // Example 2: Change width constraint(s) of this view to a specific value
    // Make sure that we are looking at an equality constraint (not inequality)
    // and that the constraint is not against another view
    func changeWidth(to value: CGFloat) {

        getAllConstraints().filter( {
            $0.firstAttribute == .width &&
                $0.relation == .equal &&
                $0.secondAttribute == .notAnAttribute
        } ).forEach( {$0.constant = value })
    }
    
    func changeRight(to value: CGFloat) {

       getAllConstraints().filter( {
            $0.firstAttribute == .right &&
                $0.firstItem as? UIView == self
        }).forEach({$0.constant = value})
    }

    // Example 3: Change leading constraints only where this view is
    // mentioned first. We could also filter leadingMargin, left, or leftMargin
    func changeLeading(to value: CGFloat) {
        getAllConstraints().filter( {
            $0.firstAttribute == .leading &&
                $0.firstItem as? UIView == self
        }).forEach({$0.constant = value})
    }
    func changeLeft(to value: CGFloat) {
        getAllConstraints().filter( {
            $0.firstAttribute == .left &&
                $0.firstItem as? UIView == self
        }).forEach({$0.constant = value})
    }
    
    func changeBottom(to value: CGFloat) {
          getAllConstraints().filter( {
              $0.firstAttribute == .bottom &&
                  $0.firstItem as? UIView == self
        }).forEach({$0.constant = value})
    }
    
    func changeBottomMargin(to value: CGFloat) {
          getAllConstraints().filter( {
            $0.firstAttribute == .bottomMargin &&
                  $0.firstItem as? UIView == self
        }).forEach({$0.constant = value})
    }
    
    func changeTop(to value: CGFloat) {
          getAllConstraints().filter( {
              $0.firstAttribute == .top &&
                  $0.firstItem as? UIView == self
        }).forEach({$0.constant = value})
    }
}

private class BorderView: UIView {}
