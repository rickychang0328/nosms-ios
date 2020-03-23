
import UIKit
import RxCocoa
import RxSwift

class CircleView: UIView {
    
    var lineWidth: CGFloat = 3
    
    var shapeLayer: CAShapeLayer = .init()
    
    var subLayer: CAShapeLayer = .init()
    
    var animation: CABasicAnimation = .init()
    
    
    func getCircleSubLayer(circleLast: Double = 0) {
        
        layoutIfNeeded()
        superview?.layoutIfNeeded()
        subLayer.removeFromSuperlayer()
        
        let shapeLayer = CAShapeLayer()
        self.subLayer = shapeLayer
        shapeLayer.frame = CGRect(x: 0, y: 0, width: frame.width / 2, height: frame.width / 2)
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = lineWidth
        shapeLayer.strokeColor = UIColor.clear.cgColor
        let arcCenter:CGPoint = shapeLayer.position // 設定圓心
        let radius:CGFloat = frame.width / 2 - lineWidth // 設定半徑
        // 剩下沒設置到的參數就為起始角度跟結束角度，最後為是否順時針
        let path = UIBezierPath(arcCenter: arcCenter,
                                radius: radius,
                                startAngle: CGFloat(2 * Float.pi / 4 * 3),
                                endAngle: CGFloat(2 * Float.pi / 4 * 3) + (CGFloat(2 * Float.pi) * (1 - CGFloat(circleLast))), clockwise: true)
        
        shapeLayer.path = path.cgPath
        shapeLayer.position = center
        layer.addSublayer(shapeLayer)
    }
    
    func getCircle(circleLast: Double = 1, circleTo: Double = 1) {
        
        layoutIfNeeded()
        superview?.layoutIfNeeded()
        shapeLayer.removeFromSuperlayer()
        
        let shapeLayer = CAShapeLayer()
        self.shapeLayer = shapeLayer
        shapeLayer.frame = CGRect(x: 0, y: 0, width: frame.width / 2, height: frame.width / 2)
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = lineWidth
        shapeLayer.strokeColor = UIColor.countColor.cgColor
        let arcCenter:CGPoint = shapeLayer.position // 設定圓心
        let radius:CGFloat = frame.width / 2 - lineWidth // 設定半徑
        // 剩下沒設置到的參數就為起始角度跟結束角度，最後為是否順時針
        let path = UIBezierPath(arcCenter: arcCenter,
                                radius: radius,
                                startAngle: CGFloat(2 * Float.pi / 4 * 3) + (CGFloat(2 * Float.pi) * (1 - CGFloat(circleLast))),
                                endAngle: CGFloat(2 * Float.pi / 4 * 3) + (CGFloat(2 * Float.pi) * (1 - CGFloat(circleTo))),
                                clockwise: true)
        
        shapeLayer.path = path.cgPath
        shapeLayer.position = center
        layer.addSublayer(shapeLayer)
    }
    
    func startAnimation(lastTime: Double, refreshTime: Double) {
        
        let last = lastTime / refreshTime
        let toWhere = (lastTime - 1) / refreshTime
        getCircleSubLayer(circleLast: last)
        getCircle(circleLast: last, circleTo: toWhere)
        
        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.fromValue = 0
        animation.toValue = 1
        animation.duration = 1
        self.animation = animation
        shapeLayer.add(animation, forKey: nil)
    }
}

class NoSMSCircleLoadView: UIView {
    
    private let loadingCricleView: CircleView = {
        
        let view = CircleView()
        return view
    }()
    
    private let baseCricleView: CircleView = {
        
        let view = CircleView()
        return view
    }()

    var loadingColorBinder: Binder<UIColor> {
        
        return Binder<UIColor>.init(self) { (view, color) in
            
            view.bindingUIColor = color
            view.baseCricleView.subLayer.strokeColor = color.cgColor
        }
    }
    
    //MARK: 紀錄重新生成 layer 需要的值
    private var bindingUIColor: UIColor = .clear
    private var lastTime: Double = 0
    private var reFreshTime: Double = 0
    
    private var disposeBag: DisposeBag = .init()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(baseCricleView)
        addSubview(loadingCricleView)
        
        baseCricleView.snp.makeConstraints {
            
            $0.edges.equalToSuperview()
        }
        loadingCricleView.snp.makeConstraints {
            
            $0.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func startAnimation(lastTime: Double, refreshTime: Double) {
        
        self.reFreshTime = refreshTime
        defer {
            self.lastTime = lastTime
        }
        
        if self.lastTime == lastTime {
            
            return
        }
        baseCricleView.getCircleSubLayer()
        loadingCricleView.startAnimation(lastTime: lastTime, refreshTime: refreshTime)
        setupCGColor()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        resetInDarkModeChange()
        setupCGColor()
        layoutIfNeeded()
    }
    
    
    //MARK: CAShapeLayer 用 Path 沒辦法在知道後直接更換顏色有點怪 直接重新生成一個 shapeLayer
    private func resetInDarkModeChange() {
        
        baseCricleView.getCircleSubLayer()
        let last = lastTime / reFreshTime
        loadingCricleView.getCircleSubLayer(circleLast: last)
    }
    
    private func setupCGColor() {
        
        baseCricleView.subLayer.strokeColor = bindingUIColor.cgColor
        loadingCricleView.shapeLayer.strokeColor = UIColor.circleViewBackColor.cgColor
        loadingCricleView.subLayer.strokeColor = UIColor.circleViewBackColor.cgColor
    }
    
    func remove() {
        
        baseCricleView.subLayer.removeFromSuperlayer()
        loadingCricleView.shapeLayer.removeFromSuperlayer()
        loadingCricleView.subLayer.removeFromSuperlayer()
    }
}
