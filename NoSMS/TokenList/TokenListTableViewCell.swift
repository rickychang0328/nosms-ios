
import UIKit
import RxCocoa
import RxSwift

protocol TokenListTableViewCellViewModelProtocol: BaseTableViewCellViewModelProtocol {
    
    var name: BehaviorSubject<String> { get }
    var password: Observable<String> { get }
    var issuer: Observable<String> { get }
    var lastTime: BehaviorSubject<String> { get }
    var haveSelectToDelete: BehaviorSubject<Bool> { get }
    var passwordCount: Int { get }
    var isOnTime: Bool { get }
    var getTapPassword: () -> Void { get }
    var reFreshTime: Int { get }
    var passwordShow: Observable<Bool> { get }
}

class TokenListTableViewCellViewModel: TokenListTableViewCellViewModelProtocol {
    
    let passwordShow: Observable<Bool>
    
    let reFreshTime: Int
    
    let getTapPassword: () -> Void
    
    let haveSelectToDelete: BehaviorSubject<Bool>

    let baseCellItem: BaseTableViewCellViewModelItemProtocol

    let name: BehaviorSubject<String>
    
    let password: Observable<String>
    
    let issuer: Observable<String>
    
    let lastTime: BehaviorSubject<String>
    
    var cellFactoryType: TableViewCellFactoryType { .tokenListWithTime(viewModel: self) }
    
    let passwordCount: Int
    
    let isOnTime: Bool
    
    internal init(baseViewModelItem: BaseTableViewCellViewModelItemProtocol,
                  name: BehaviorSubject<String>,
                  password: Observable<String>,
                  issuer: Observable<String>,
                  lastTime: BehaviorSubject<String>,
                  haveSelectToDelete: BehaviorSubject<Bool>,
                  passwordCount: Int,
                  isOnTime: Bool,
                  getTapPassword: @escaping () -> Void,
                  refreshTime: Int,
                  passwordShow: Observable<Bool>) {
        self.getTapPassword = getTapPassword
        self.baseCellItem = baseViewModelItem
        self.name = name
        self.reFreshTime = refreshTime
        self.password = password.map({
            
            var string = $0
            
            if string.isEmpty {
                
                return " "
            }
            
            let index: String.Index
            if passwordCount == 6 {
                index = string.index(string.startIndex, offsetBy: 3)
            } else {
                index = string.index(string.startIndex, offsetBy: 4)
            }
            string.insert(" ", at: index)
            return string
        })
        self.issuer = issuer
        self.lastTime = lastTime
        self.haveSelectToDelete = haveSelectToDelete
        self.passwordCount = passwordCount
        self.isOnTime = isOnTime
        self.passwordShow = passwordShow
    }
}
 
class TokenListTableViewCell<ViewModel: TokenListTableViewCellViewModelProtocol>: BaseTableViewCell<ViewModel> {
    
    private let nameLabel: UILabel = {
       
        let label = UILabel()
        label.setFont(.pingFangMediumFont(size: 15))
            .setTextColor(.nameColor)
        return label
    }()
    
    private let nameTextField: UITextField = {
        
        let textField = UITextField()
        textField.font = .pingFangMediumFont(size: 15)
        textField.textColor = .nameColor
        return textField
    }()
    
    private let passwordLabel: UILabel = {
          
        let label = UILabel()
        label.setFont(.arialMTFont(size: 45))
            .setTextColor(.sercetNormalColor)
        return label
    }()
    
    private let issuerLabel: UILabel = {
          
        let label = UILabel()
        label.setTextColor(.issuerColor)
            .setFont(.pingFangMediumFont(size: 15))
        return label
    }()
    
    private let countTimeLabel: UILabel = {
        
        let label = UILabel()
        label.setFont(.avenirHeavyFont(size: 11))
            .setTextColor(.countColor)
            .setTextAlignment(.center)
        return label
    }()
    
    private let tapGetPasswordButton: UIButton = {
        
        let button = UIButton()
        button.setImage(.noSmsRefresh, for: .normal)
        return button
    }()
    
    private let backCardView: UIView = {
       
        let view = UIView()
        view.setBackgroundColor(.white)
        return view
    }()
    
    private let deletedButton: UIButton = {
       
        let button = UIButton()
        return button
    }()
    
    private let deleteImageView: UIImageView = .init(image: .noSmsNoSelected)
    
    private let digitsView: DigitsView = .init(frame: .zero)
    
    private var isOnTime: Bool = false
    
    private var hotpShowPassword: Bool = false
    
    private let circleView: NoSMSCircleLoadView = NoSMSCircleLoadView()
        
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        layoutView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func layoutView() {
        
        addSubview(backCardView)
        sendSubviewToBack(backCardView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(nameTextField)
        contentView.addSubview(passwordLabel)
        contentView.addSubview(issuerLabel)
        contentView.addSubview(circleView)
        circleView.addSubview(countTimeLabel)
        contentView.addSubview(tapGetPasswordButton)
        addSubview(deleteImageView)
        addSubview(deletedButton)
        contentView.addSubview(digitsView)
        
        issuerLabel.snp.makeConstraints {
            
            $0.top.left.equalTo(ScaleWidth(at: 16))
            $0.right.equalTo(ScaleWidth(at: -16))
        }
    
        deleteImageView.snp.makeConstraints {
            
            $0.centerY.equalTo(passwordLabel)
            $0.right.equalTo(contentView.snp.left)
            $0.height.equalTo(ScaleWidth(at: 18))
            $0.width.equalTo(ScaleWidth(at: 18))
        }
        
        deletedButton.snp.makeConstraints {
            
            $0.top.bottom.left.equalToSuperview()
            $0.right.equalTo(contentView.snp.left).offset(20)
        }

        passwordLabel.snp.makeConstraints {
            
            $0.left.right.equalTo(issuerLabel)
            $0.top.equalTo(issuerLabel.snp.bottom).offset(ScaleWidth(at: 10))
        }
        
        nameLabel.snp.makeConstraints {
            
            $0.left.equalTo(issuerLabel)
            $0.right.equalTo(ScaleWidth(at: -50))
            $0.top.equalTo(passwordLabel.snp.bottom).offset(ScaleWidth(at: 10)).priorityLow()
            $0.bottom.equalToSuperview().offset(ScaleWidth(at: -20))
        }
        
        nameTextField.snp.makeConstraints {
                  
            $0.left.centerY.equalTo(nameLabel).offset(1)
            $0.right.equalTo(ScaleWidth(at: -16))
        }
        
        let textFieldUnderLine = UIView()
        textFieldUnderLine.setBackgroundColor(.textFieldUnderLineColor)
        nameTextField.addSubview(textFieldUnderLine)
        textFieldUnderLine.snp.makeConstraints {
            
            $0.left.right.equalToSuperview()
            $0.bottom.equalTo(ScaleWidth(at: 4))
            $0.height.equalTo(1)
        }
        
        backCardView.snp.makeConstraints {
            
            $0.top.left.right.equalToSuperview()
            $0.bottom.equalTo(ScaleWidth(at: -4))
        }
    
        countTimeLabel.snp.makeConstraints {
            
            $0.center.equalTo(circleView)
        }
        
        circleView.snp.makeConstraints {
            
            $0.size.equalTo(ScaleWidth(at: 27))
            $0.centerY.equalTo(nameLabel)
            $0.right.equalTo(ScaleWidth(at: -16))
        }
        
        tapGetPasswordButton.snp.makeConstraints {
            
            $0.edges.equalTo(circleView)
        }
        
        digitsView.snp.makeConstraints {
            
            $0.edges.equalTo(passwordLabel)
        }
        digitsView.isHidden = true
 
    }
    
    private func changeLayout() {
        
        UIView.animate(withDuration: 0.1, animations: {
            
            self.nameLabel.isHidden = self.isEditing
            self.circleView.isHidden = self.isEditing
            self.passwordLabel.isHidden = self.isEditing
            self.nameTextField.isHidden = !self.isEditing
            self.deletedButton.isEnabled = self.isEditing
            self.digitsView.isHidden = !self.isEditing

            if self.isOnTime {
                
                self.tapGetPasswordButton.isHidden = true
                self.digitsView.isHidden = !self.isEditing
            } else {
                
                self.tapGetPasswordButton.isHidden = self.isEditing
                
                if !self.isEditing && !self.hotpShowPassword {
                    
                    self.digitsView.isHidden = false
                    self.passwordLabel.isHidden = true
                }
            }
            
        }, completion: nil)
        
        if isEditing {
            
            for view in self.subviews {
                
                if view.description.contains("UITableViewCellReorderControl") {

                    let imageOfReorder = view.subviews[0] as? UIImageView
                    imageOfReorder?.image = nil
                    let imageView = UIImageView(image: .noSmsMoveCell)
                    imageView.frame = .init(x: 0, y: 0, width: ScaleWidth(at: 18), height: ScaleWidth(at: 13.5))
                    view.addSubview(imageView)
                    imageView.center = .init(x: ScaleWidth(at: 10), y: passwordLabel.center.y)
                }
            }
            
            digitsView.setColor(UIColor.black.withAlphaComponent(0.1))
        } else {
            
            digitsView.setColor(.black)
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: true)
        
        changeLayout()
    }
    
    override func bindData(viewModel: ViewModel) {
        super.bindData(viewModel: viewModel)
        
        let name = viewModel.name
                    .asDriver(onErrorJustReturn: "")
            
        name.drive(nameLabel.rx.text)
            .disposed(by: disposedBag)
        name.drive(nameTextField.rx.text)
            .disposed(by: disposedBag)

        viewModel.issuer
            .bind(to: issuerLabel.rx.text)
            .disposed(by: disposedBag)
        
        viewModel.password
            .bind(to: passwordLabel.rx.text)
            .disposed(by: disposedBag)
        
        //hotp 的密碼是否顯示
        viewModel.passwordShow
            .subscribe(onNext: { [weak self] hotpShowPassword in
                
                self?.hotpShowPassword = hotpShowPassword
                self?.changeLayout()
            }).disposed(by: disposedBag)
        
        viewModel.lastTime
            .bind(to: countTimeLabel.rx.text)
            .disposed(by: disposedBag)
        
        digitsView.setDigits(count: viewModel.passwordCount)
        
        isOnTime = viewModel.isOnTime
        tapGetPasswordButton.isHidden = viewModel.isOnTime
        
        tapGetPasswordButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.tapGetPasswordButton.isEnabled = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                    
                    self?.tapGetPasswordButton.isEnabled = true
                }
            }).disposed(by: disposedBag)
        tapGetPasswordButton.rx.tap
            .subscribe(onNext: viewModel.getTapPassword)
            .disposed(by: disposedBag)
       
        let warningTime = viewModel.lastTime.compactMap({Int($0)}).map({$0 < 6})
        
        let isOnTime = viewModel.isOnTime
        passwordLabel.setTextColor(.sercetNormalColor)
        
        warningTime.map({ if isOnTime {
            
                    return $0 ? UIColor.sercetWarninglColor : UIColor.sercetNormalColor

                } else {
                    
                    return UIColor.sercetNormalColor
                }
            }).bind(to: passwordLabel.rx.textColor)
            .disposed(by: disposedBag)
        
        viewModel.haveSelectToDelete
            .bind(to: deletedButton.rx.isSelected)
            .disposed(by: disposedBag)
        
        viewModel.haveSelectToDelete
            .map({ $0 ? UIImage.noSmsSelectedDelete : UIImage.noSmsNoSelected})
            .bind(to: deleteImageView.rx.image)
            .disposed(by: disposedBag)

        let haveSeletToDelete = viewModel.haveSelectToDelete

        deletedButton.rx.tap.subscribe(onNext: { [weak self, weak haveSeletToDelete] _ in

            guard let self = self else { return }
            self.deletedButton.isSelected = !self.deletedButton.isSelected
            haveSeletToDelete?.onNext(self.deletedButton.isSelected)
        }).disposed(by: disposedBag)
        
        nameTextField.rx.controlEvent(.editingDidEnd)
            .flatMapLatest({[unowned self] in return self.nameTextField.rx.text.orEmpty })
            .bind(to: viewModel.name)
            .disposed(by: disposedBag)
        
        if isOnTime {
            
            let reFreshTime = viewModel.reFreshTime
            viewModel.lastTime.subscribe(onNext: { [weak self] lastTimeString in

                    guard let self = self else { return }
                    guard let lastTime = Int(lastTimeString) else { return }
                
                    
                    self.circleView.startAnimation(lastTime: Double(lastTime), refreshTime: Double(reFreshTime - 1))

                }).disposed(by: disposedBag)
        } else {
            
            circleView.remove()
        }
        
        warningTime.map({ $0 ? UIColor.countWarningColor : UIColor.countColor })
            .bind(to: countTimeLabel.rx.textColor, circleView.loadingColorBinder)
            .disposed(by: disposedBag)
    }
}

class DigitsView: UIView {
    
    private var counterViews: [UIView] = []
    
    func setColor(_ color: UIColor) {
        
        counterViews.forEach({$0.backgroundColor = color})
    }
    
    func setDigits(count: Int) {
        
        counterViews.forEach({$0.removeFromSuperview()})
        
        counterViews = []
        for _ in 0 ..< count {
            
            let view = UIView()
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
            
            view.baseCricleView.subLayer.strokeColor = color.cgColor
        }
    }
    
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

        baseCricleView.getCircleSubLayer()
        loadingCricleView.startAnimation(lastTime: lastTime, refreshTime: refreshTime)
        loadingCricleView.shapeLayer.strokeColor = UIColor(red: 216/255, green: 216/255, blue: 216/255, alpha: 1).cgColor
        loadingCricleView.subLayer.strokeColor = UIColor(red: 216/255, green: 216/255, blue: 216/255, alpha: 1).cgColor
    }
    
    func remove() {
        
        baseCricleView.subLayer.removeFromSuperlayer()
        loadingCricleView.shapeLayer.removeFromSuperlayer()
        loadingCricleView.subLayer.removeFromSuperlayer()
    }
}
