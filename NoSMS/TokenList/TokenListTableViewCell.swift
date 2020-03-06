
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
    var isInSearch: BehaviorSubject<Bool> { get }
}

class TokenListTableViewCellViewModel: TokenListTableViewCellViewModelProtocol {
    
    let isInSearch: BehaviorSubject<Bool> = .init(value: false)
    
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
 
class TokenListTableViewCell<ViewModel: TokenListTableViewCellViewModelProtocol>: BaseTableViewCell<ViewModel>, UITextFieldDelegate {
    
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
    
    private let moveImageView: UIImageView = {
        
        let imageView = UIImageView(image: .noSmsMoveCell)
        imageView.frame = .init(x: 0, y: 0, width: ScaleWidth(at: 18), height: ScaleWidth(at: 13.5))
        
        return imageView
    }()
    
    private var isInSearch: Bool = false
        
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
        
        nameTextField.delegate = self
    }
    func runBackCardAnimation() {
        UIView.animate(withDuration: 0.3, animations: {
            //animation 1
            self.backCardView.backgroundColor = UIColor(red: 239/255, green: 239/255, blue: 255/255, alpha: 1)
//            self.backCardView.backgroundColor = .red
        }, completion: { (value: Bool) in
            UIView.animate(withDuration: 0.1, animations: {
                //animation 2
                self.backCardView.backgroundColor = .white
            })
        })
    }
    func setBackCardAnimationColor(){
        
        for i in 1...3 {
//            if i == 1 {
//                runBackCardAnimation()
//            }else {
            let asyncTime:Double = Double(i) * 0.4
                DispatchQueue.main.asyncAfter(deadline: .now() + asyncTime) { [weak self] in
                    self?.runBackCardAnimation()
                }
//            }
            
        }
        
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        return true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        moveImageView.removeFromSuperview()
    }
    
    private func changeLayout() {
        
        UIView.animate(withDuration: 0.1, animations: {
            
            self.nameLabel.isHidden = self.isEditing
            self.passwordLabel.isHidden = self.isEditing
            self.nameTextField.isHidden = !self.isEditing
            self.deletedButton.isEnabled = self.isEditing
            self.digitsView.isHidden = !self.isEditing

            if self.isOnTime {
                
                self.circleView.isHidden = self.isEditing
                self.tapGetPasswordButton.isHidden = true
                self.digitsView.isHidden = !self.isEditing
            } else {
                self.circleView.isHidden = true
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
                    view.addSubview(moveImageView)
                    moveImageView.center = .init(x: ScaleWidth(at: 10), y: passwordLabel.center.y)
                    
                    view.isHidden = isInSearch
                }
            }
            
            digitsView.setColor(UIColor.black.withAlphaComponent(0.1))
        } else {
            
            moveImageView.removeFromSuperview()
            digitsView.setColor(.black)
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: true)
        
        changeLayout()
    }
    
    override func bindData(viewModel: ViewModel) {
        super.bindData(viewModel: viewModel)
        
        //給空白讓 label 的 auto 高不會跑掉
        let name = viewModel.name.map({
          
            if $0.isEmpty {
                
                return " "
            } else {
                
                return $0
            }
        }).asDriver(onErrorJustReturn: "")
            
        name.drive(nameLabel.rx.text)
            .disposed(by: disposedBag)
        viewModel.name.bind(to:nameTextField.rx.text)
            .disposed(by: disposedBag)

        viewModel.issuer
            .bind(to: issuerLabel.rx.text)
            .disposed(by: disposedBag)
        
        viewModel.password
            .bind(to: passwordLabel.rx.text)
            .disposed(by: disposedBag)
        
        //hotp 的密碼是否顯示 有動作後要讓 button 不能按一陣子
        viewModel.passwordShow
            .subscribe(onNext: { [weak self] hotpShowPassword in
                
                self?.hotpShowPassword = hotpShowPassword
                
                if hotpShowPassword {
                    
                    self?.tapGetPasswordButton.isEnabled = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self?.tapGetPasswordButton.isEnabled = true
                    }
                }
                self?.changeLayout()
            }).disposed(by: disposedBag)
        // 先預設給按
        tapGetPasswordButton.isEnabled = true
        
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
            
            circleView.isHidden = false
            let reFreshTime = viewModel.reFreshTime
            viewModel.lastTime.subscribe(onNext: { [weak self] lastTimeString in

                    guard let self = self else { return }
                    guard let lastTime = Int(lastTimeString) else { return }
                
                    
                    self.circleView.startAnimation(lastTime: Double(lastTime), refreshTime: Double(reFreshTime - 1))

                }).disposed(by: disposedBag)
        } else {
            
            circleView.isHidden = true
        }
        
        warningTime.map({ $0 ? UIColor.countWarningColor : UIColor.countColor })
            .bind(to: countTimeLabel.rx.textColor, circleView.loadingColorBinder)
            .disposed(by: disposedBag)
        
        viewModel.isInSearch.subscribe(onNext: { [weak self] isInSearch in
            guard let self = self else { return }
            self.isInSearch = isInSearch
            self.changeLayout()
            
            }).disposed(by: disposedBag)
    }
}
