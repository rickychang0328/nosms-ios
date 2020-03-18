import UIKit

//MARK: iOS 12 以下拖移時會莫名其妙不知道從哪改變到 view 的顏色找不到
class NeverClearColorView: UIView {
    
    override var backgroundColor: UIColor? {
     
        didSet {
            
            if self.backgroundColor == .clear {
                
                self.backgroundColor = oldValue
            }
        }
    }

}

class DigitsView: UIView {
    
    private var counterViews: [NeverClearColorView] = []
    
    func setColor(_ color: UIColor) {
        
        counterViews.forEach({$0.backgroundColor = color})
    }
    
    func setDigits(count: Int) {
        
        counterViews.forEach({$0.removeFromSuperview()})
        
        counterViews = []
      
        for _ in 0 ..< count {
            
            let view = NeverClearColorView()
            view.setBackgroundColor(UIColor.black)
            view.addCornerRadius(at: 7)
            counterViews.append(view)
        }
        
        let whichIndexSpace: Int
        
        if count <= 6 {
            
            whichIndexSpace = 3
        } else {
            
            whichIndexSpace = 4
        }
        
        for index in counterViews.indices {
            
            let view = counterViews[index]
            addSubview(view)
            
            let leftOffset: CGFloat
            
            if index == whichIndexSpace {
                
                leftOffset = ScaleWidth(at: 30)
                
            } else {
                
                leftOffset = ScaleWidth(at: 15)
            }
            
            view.snp.makeConstraints {
                
                $0.size.equalTo(14)
                
                if index == 0 {
                    
                    $0.left.equalToSuperview()
                } else {
                    
                    $0.left.equalTo(counterViews[index - 1].snp.right).offset(leftOffset)
                }
                $0.centerY.equalToSuperview()
            }
        }
    }
}

