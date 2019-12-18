
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
}

class TokenListTableViewCellViewModel: TokenListTableViewCellViewModelProtocol {
    
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
                  getTapPassword: @escaping () -> Void) {
        self.getTapPassword = getTapPassword
        self.baseCellItem = baseViewModelItem
        self.name = name
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
        return label
    }()
    
    private let tapGetPasswordButton: UIButton = {
        
        let button = UIButton()
        button.setImage(UIImage.noSmsAdd.withRenderingMode(.alwaysTemplate), for: .normal)
        button.setTitle("tap", for: .normal)
        button.tintColor = .countColor
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
        contentView.addSubview(countTimeLabel)
        contentView.addSubview(tapGetPasswordButton)
        addSubview(deleteImageView)
        contentView.addSubview(deletedButton)
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
            
            $0.top.left.bottom.equalToSuperview()
            $0.right.equalTo(contentView.snp.left).offset(20)
        }

        passwordLabel.snp.makeConstraints {
            
            $0.left.right.equalTo(issuerLabel)
            $0.top.equalTo(issuerLabel.snp.bottom).offset(ScaleWidth(at: 10))
        }
        
        nameLabel.snp.makeConstraints {
            
            $0.left.right.equalTo(issuerLabel)
            $0.top.equalTo(passwordLabel.snp.bottom).offset(ScaleWidth(at: 10))
            $0.bottom.equalToSuperview().offset(ScaleWidth(at: -20))
        }
        
        nameTextField.snp.makeConstraints {
                  
            $0.left.right.centerY.equalTo(nameLabel).offset(1)
        }
        
        let textFieldUnderLine = UIView()
        textFieldUnderLine.setBackgroundColor(.gray)
        nameTextField.addSubview(textFieldUnderLine)
        textFieldUnderLine.snp.makeConstraints {
            
            $0.left.right.bottom.equalToSuperview()
            $0.height.equalTo(1)
        }
        
        backCardView.snp.makeConstraints {
            
            $0.top.left.right.equalToSuperview()
            $0.bottom.equalTo(ScaleWidth(at: -4))
        }
    
        countTimeLabel.snp.makeConstraints {
            
            $0.centerY.equalTo(nameLabel)
            $0.right.equalTo(issuerLabel)
        }
        
        tapGetPasswordButton.snp.makeConstraints {
            
            $0.centerY.equalTo(passwordLabel)
            $0.right.equalTo(issuerLabel)
            $0.size.equalTo(ScaleWidth(at: 32))
        }
        
        digitsView.snp.makeConstraints {
            
            $0.edges.equalTo(passwordLabel)
        }
        digitsView.isHidden = true
    }
    
    private func changeLayout() {
        
        UIView.animate(withDuration: 0.3, animations: {
            
            self.nameLabel.isHidden = self.isEditing
            self.countTimeLabel.isHidden = self.isEditing
            self.passwordLabel.isHidden = self.isEditing
            self.nameTextField.isHidden = !self.isEditing
            self.deletedButton.isEnabled = self.isEditing
            self.digitsView.isHidden = !self.isEditing
            
            if self.isOnTime {
                
                self.tapGetPasswordButton.isHidden = true
            } else {
                
                self.tapGetPasswordButton.isHidden = self.isEditing
            }
        }, completion: nil)
        
        if isEditing {
            
            for view in self.subviews {
                
                if view.description.contains("UITableViewCellReorderControl") {

                    let imageOfReorder = view.subviews[0] as? UIImageView
                    imageOfReorder?.image = .noSmsMoveCell
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
        
        viewModel.lastTime
            .bind(to: countTimeLabel.rx.text)
            .disposed(by: disposedBag)
        
        digitsView.setDigits(count: viewModel.passwordCount)
        
        isOnTime = viewModel.isOnTime
        tapGetPasswordButton.isHidden = viewModel.isOnTime
        
        tapGetPasswordButton.rx.tap
            .subscribe({ [weak self] _ in
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
        
        warningTime.map({ $0 ? UIColor.countWarningColor : UIColor.countColor })
            .bind(to: countTimeLabel.rx.textColor)
            .disposed(by: disposedBag)
        
        viewModel.haveSelectToDelete
            .bind(to: deletedButton.rx.isSelected)
            .disposed(by: disposedBag)
        
        viewModel.haveSelectToDelete
            .map({ $0 ? UIImage.noSmsSelectedDelete : UIImage.noSmsNoSelected})
            .bind(to: deleteImageView.rx.image)
            .disposed(by: disposedBag)

        let haveSeletToDelete = viewModel.haveSelectToDelete

        deletedButton.rx.tap.subscribe { [weak self, weak haveSeletToDelete] _ in

            guard let self = self else { return }
            self.deletedButton.isSelected = !self.deletedButton.isSelected
            haveSeletToDelete?.onNext(self.deletedButton.isSelected)
        }.disposed(by: disposedBag)
        
        nameTextField.rx.controlEvent(.editingDidEnd)
            .flatMapLatest({[unowned self] in return self.nameTextField.rx.text.orEmpty })
            .bind(to: viewModel.name)
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
