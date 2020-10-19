
import UIKit
import RxCocoa
import RxSwift


protocol TokenListTableViewCellViewModelProtocol: BaseTableViewCellViewModelProtocol, BaseTokenListViewType {
    
    var name: BehaviorSubject<String> { get }
    var lastTime: BehaviorSubject<String> { get }
    var haveSelectToDelete: BehaviorSubject<Bool> { get }
    var isOnTime: Bool { get }
    var getTapPassword: () -> Void { get }
    var reFreshTime: Int { get }
    var passwordShow: Observable<Bool> { get }
    var isInSearch: BehaviorSubject<Bool> { get }
    var warningTime: Observable<Bool> { get }
    var tokenID: Data { get }
    var isPin: Bool { get }
    var addPin: () -> Void { get }
    var removePin: () -> Void { get }
    func setPin(isPin: Bool)
}

class TokenListTableViewCellViewModel: TokenListTableViewCellViewModelProtocol {
    
    func setPin(isPin: Bool) {
        self.isPin = isPin
    }
    
    let addPin: () -> Void
    
    let removePin: () -> Void
    
    var isPin: Bool = false
    
    let tokenID: Data
    
    var passwordColor: Observable<UIColor> {
        
        return warningTime.map({ if self.isOnTime {
            
            return $0 ? UIColor.tokenListWarningPasswordColor : UIColor.tokenListPasswordColor
            
        } else {
            
            return UIColor.tokenListPasswordColor
            }
        })
    }
    
    var warningTime: Observable<Bool> {
        
        return lastTime.compactMap({Int($0)}).map({$0 < 6})
    }
    
    let isInSearch: BehaviorSubject<Bool> = .init(value: false)
    
    let passwordShow: Observable<Bool>
    
    let reFreshTime: Int
    
    let getTapPassword: () -> Void
    
    let haveSelectToDelete: BehaviorSubject<Bool>
    
    let baseCellItem: BaseTableViewCellViewModelItemProtocol
    
    let name: BehaviorSubject<String>
    
    let password: Observable<String>
    
    let issuer: BehaviorSubject<String>
    
    let lastTime: BehaviorSubject<String>
    
    var cellFactoryType: TableViewCellFactoryType { .tokenListWithTime(viewModel: self) }
    
    let passwordCount: Int
    
    let isOnTime: Bool
    
    internal init(baseViewModelItem: BaseTableViewCellViewModelItemProtocol,
                  name: BehaviorSubject<String>,
                  password: Observable<String>,
                  issuer: BehaviorSubject<String>,
                  lastTime: BehaviorSubject<String>,
                  haveSelectToDelete: BehaviorSubject<Bool>,
                  passwordCount: Int,
                  isOnTime: Bool,
                  getTapPassword: @escaping () -> Void,
                  refreshTime: Int,
                  passwordShow: Observable<Bool>,
                  uuid: Data,
                  addPin: @escaping () -> Void,
                  removePin: @escaping () -> Void) {
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
        self.tokenID = uuid
        self.addPin = addPin
        self.removePin = removePin
    }
}


class BaseTokenListView: UIView {
    
    let selectImageView: UIImageView = .init(image: .noSmsNoSelected)
    
    let nameLabel: UILabel = {
        
        let label = UILabel()
        label.setFont(.pingFangMediumFont(size: 15))
            .setTextColor(.tokenListAccountColor)
        return label
    }()
    
    let passwordLabel: UILabel = {
        
        let label = UILabel()
        label.setFont(.arialMTFont(size: 45))
            .setTextColor(.tokenListPasswordColor)
        return label
    }()
    
    let issuerLabel: UILabel = {
        
        let label = UILabel()
        label.setTextColor(.tokenListIssuerColor)
            .setFont(.pingFangMediumFont(size: 15))
        return label
    }()
    
    let digitsView: DigitsView = .init(frame: .zero)
    
    var disposedBag: DisposeBag = .init()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        selectImageView.isHidden = true
        addSubview(issuerLabel)
        addSubview(passwordLabel)
        addSubview(nameLabel)
        addSubview(digitsView)
        addSubview(selectImageView)
        
        issuerLabel.snp.makeConstraints {
            
            $0.top.left.equalTo(ScaleWidth(at: 16))
            $0.right.equalTo(ScaleWidth(at: -16))
        }
        
        passwordLabel.snp.makeConstraints {
            
            $0.left.right.equalTo(issuerLabel)
            $0.top.equalTo(issuerLabel.snp.bottom).offset(ScaleWidth(at: 10))
        }
        
        nameLabel.snp.makeConstraints {
            
            $0.left.equalTo(issuerLabel)
            $0.right.equalTo(ScaleWidth(at: -50))
            $0.top.equalTo(passwordLabel.snp.bottom).offset(ScaleWidth(at: 10)).priorityLow()
            //            $0.bottom.equalToSuperview().offset(ScaleWidth(at: -20))
        }
        
        digitsView.snp.makeConstraints {
            
            $0.edges.equalTo(passwordLabel)
        }
        
        selectImageView.snp.makeConstraints {
            
            $0.top.equalTo(ScaleWidth(at: 59))
            $0.right.equalToSuperview().inset(ScaleWidth(at: 20))
            $0.size.equalTo(ScaleWidth(at: 27))
        }
        
        digitsView.isHidden = true
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func bindData(viewModel: BaseTokenListViewType) {
        disposedBag = .init()
        do {
            let a = try viewModel.name.value()
        } catch {
            print("User creation failed with error: \(error)")
        }
        //MARK: 給空白讓 label 的 auto 高不會跑掉
        let name = viewModel.name.map({ string -> String in
            
            if string.isEmpty {
                
                return " "
            } else {
                
                return string
            }
        })
        
        let issuer = viewModel.issuer.map({ string -> String in
            
            if string.isEmpty {
                
                return " "
            } else {
                
                return string
            }
        })
        
        name.bind(to: nameLabel.rx.text)
            .disposed(by: disposedBag)
        
        issuer
            .bind(to: issuerLabel.rx.text)
            .disposed(by: disposedBag)
        viewModel.password
            .bind(to: passwordLabel.rx.text)
            .disposed(by: disposedBag)
        
        viewModel.passwordColor
            .bind(to: passwordLabel.rx.textColor)
            .disposed(by: disposedBag)
        digitsView.setDigits(count: viewModel.passwordCount)
    }
}

protocol BaseTokenListViewType {
    
    var name: BehaviorSubject<String> { get }
    var password: Observable<String> { get }
    var issuer: BehaviorSubject<String> { get }
    var passwordColor: Observable<UIColor> { get }
    var passwordCount: Int { get }
}

protocol SwipeType: UIView {
    
    func swipeOn()
    func swipeOff()
}

//MARK: 偷時間...
class SwipeManager {
    
    static let shared: SwipeManager = .init()
    var swipes: [SwipeType] = []
    private init() {}
    
    func swipeOff() {
        
        swipes.forEach( { $0.swipeOff() })
        swipes = []
    }
    
    func addSwipeType(swipe: SwipeType) {
        
        swipes.append(swipe)
    }
    
    func removeSwipeType(swipe: SwipeType) {
        
        guard let index = swipes.firstIndex(where: { $0 == swipe }) else { return }
        swipes.remove(at: index)
    }
}

class TokenListTableViewCell<ViewModel: TokenListTableViewCellViewModelProtocol>: BaseTableViewCell<ViewModel>, UITextFieldDelegate, SwipeType {
    
    var isShareOTP = false
    //var otpShareAccount = [String]()
    
    private let pinImageView: UIImageView = {
        
        let view = UIImageView.init(image: .noSMStokenListPin)
        return view
    }()
    
    private var nowGesX: CGFloat = 0
    
    private var nowCellX: CGFloat {
        
        return swipebackCardView.frame.origin.x
    }
    
    enum SwipeStatus {
        
        case on
        case off
    }
    
    private var swipeStatus: SwipeStatus = .off
    
    private let swipeWidth: CGFloat = ScaleWidth(at: 73)
    
    private let actionWidth: CGFloat = UIScreen.main.bounds.width / 3
    
    func swipeOn() {
        
        UIView.animate(withDuration: 0.2) {
            
            self.swipebackCardView.changeLeft(to: self.swipeWidth)
            self.layoutIfNeeded()
        }
        swipeStatus = .on
        SwipeManager.shared.addSwipeType(swipe: self)
    }
    
    func swipeOff() {
        
        UIView.animate(withDuration: 0.2) {
            
            self.swipebackCardView.changeLeft(to: 0)
            self.layoutIfNeeded()
        }
        swipeStatus = .off
        SwipeManager.shared.removeSwipeType(swipe: self)
    }
    
    func shareOTP(otpShareAccount: [Data]) {
        
        let gesture = UITapGestureRecognizer(target: self, action:  #selector(self.itemClick))
        self.addGestureRecognizer(gesture)
        isShareOTP = true
        pinImageView.isHidden = true
        tapGetPasswordButton.isHidden = true
        circleView.alpha = 0
        baseTokenView.passwordLabel.alpha = 0
        baseTokenView.selectImageView.isHidden = false
        baseTokenView.digitsView.isHidden = false
        baseTokenView.digitsView.setColor(.tokenListHidePasswordInEditColor)
        let name = "[\(baseTokenView.issuerLabel.text!)] \(baseTokenView.nameLabel.text!)"
        if otpShareAccount.contains(viewModel!.tokenID) {
            baseTokenView.selectImageView.image = UIImage(named: "NoSMS_groupAddSelect")
        } else {
            baseTokenView.selectImageView.image = UIImage(named: "NoSMS_oval")
        }
    }
    
    @objc func itemClick(sender : UITapGestureRecognizer) {
        //        let tokenStore: TokenStoreProtocol = KeychainTokenStore.shared
        //
        //        let token = tokenStore.tokenList[0]
        //
        //        var adapterToken:URL
        //        do {
        //            adapterToken = try token.getMustAuthTokenURL()
        //        } catch {
        //            print("User creation failed with error: \(error)")
        //        }
        let phone = self.baseTokenView.nameLabel.text ?? ""
        let issuer = baseTokenView.issuerLabel.text ?? ""
        let name = "[\(issuer)] \(phone)"
        
        
        let token = viewModel?.tokenID
        if baseTokenView.selectImageView.image == UIImage(named: "NoSMS_oval") {
            NotificationCenter.default.post(name: Notification.Name("OTPNotificationIdentifier"), object: nil, userInfo: ["name": name, "isSelect": true, "token": token!])
            baseTokenView.selectImageView.image = UIImage(named: "NoSMS_groupAddSelect")
        } else {
            NotificationCenter.default.post(name: Notification.Name("OTPNotificationIdentifier"), object: nil, userInfo: ["name": name, "isSelect": false, "token": token!])
            baseTokenView.selectImageView.image = UIImage(named: "NoSMS_oval")
        }
        
        
    }
    
    private let swipeLabel: UILabel = {
        
        let label = UILabel()
        label.setFont(.pingFangMediumFont(size: 13))
            .setTextColor(.white)
            .setText("置顶")
        return label
    }()
    
    private let swipeImageView: UIImageView = UIImageView(image: .noSMStokenListPinAction)
    
    private lazy var swipeViewSubView: UIView = {
        
        let view = UIView()
        view.addSubview(swipeImageView)
        view.addSubview(swipeLabel)
        
        swipeImageView.snp.makeConstraints {
            
            $0.right.equalToSuperview().inset(ScaleWidth(at: 16.5))
            $0.top.equalTo(ScaleWidth(at: 42.5))
            $0.size.equalTo(ScaleWidth(at: 40))
        }
        swipeLabel.snp.makeConstraints {
            
            $0.centerX.equalTo(swipeImageView)
            $0.top.equalTo(swipeImageView.snp.bottom)
        }
        
        return view
    }()
    
    private let swipeLeftView: UIView = {
        
        let view = UIView()
        view.setBackgroundColor(.tokenListCellSwipeBackgroundColor)
        return view
    }()
    
    private func swipeAction() {
        
        swipeOff()
        
        if viewModel?.isPin ?? false {
            
            viewModel?.removePin()
        } else {
            
            viewModel?.addPin()
        }
    }
    
    private var isShock: Bool = false
    
    private func addSwipeLeft() {
        
        let gestView = UIView()
        contentView.addSubview(gestView)
        
        contentView.addSubview(swipeLeftView)
        swipeLeftView.snp.makeConstraints {
            
            $0.top.width.bottom.equalTo(swipebackCardView)
            $0.right.equalTo(swipebackCardView.snp.left)
        }
        
        deletedButton.snp.makeConstraints {
            
            $0.top.bottom.left.equalToSuperview()
            $0.right.equalTo(gestView)
        }
        
        let tapGest = UITapGestureRecognizer()
        tapGest.rx.event.subscribe(onNext: { [weak self] tapGest in
            self?.swipeAction()
            
        }).disposed(by: cellDeinitDisposedBag)
        swipeLeftView.addGestureRecognizer(tapGest)
        
        gestView.snp.makeConstraints {
            
            $0.top.bottom.equalTo(swipebackCardView)
            $0.left.equalTo(swipeLeftView)
            $0.right.equalTo(swipeLeftView).offset(ScaleWidth(at: 50))
        }
        
        swipeLeftView.addSubview(swipeViewSubView)
        
        swipeViewSubView.snp.makeConstraints {
            
            $0.edges.equalToSuperview()
        }
        
        let ges = UIPanGestureRecognizer()
        let copy = UIPanGestureRecognizer()
        ges.rx.event
            .subscribe(onNext: { [weak self] panGestureRecognizer in
                guard let self = self else { return }
                
                if self.isEditing {
                    
                    return
                }
                
                switch panGestureRecognizer.state {
                    
                case .began:
                    
                    if self.nowCellX == 0 {
                        
                        SwipeManager.shared.swipeOff()
                    }
                    self.swipeLeftView.isHidden = false
                case .changed:
                    
                    let transLationX = panGestureRecognizer.translation(in: self).x
                    let moveX = self.nowGesX - transLationX
                    self.nowGesX = transLationX
                    let newX: CGFloat = self.swipebackCardView.frame.origin.x - moveX
                    
                    let resultX: CGFloat
                    
                    if newX < 0 {
                        
                        resultX = 0
                    } else {
                        
                        resultX = newX
                    }
                    
                    self.swipebackCardView.changeLeft(to: resultX)
                    
                    if self.nowCellX > self.actionWidth, !self.isShock {
                        
                        //MARK: 震動
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.prepare()
                        generator.impactOccurred()
                        self.isShock = true
                        
                    } else if self.nowCellX < self.actionWidth, self.isShock {
                        
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.prepare()
                        generator.impactOccurred()
                        self.isShock = false
                    }
                    
                case .ended:
                    if self.nowCellX > self.actionWidth {
                        
                        //MARK: swipe 行動
                        self.swipeAction()
                    } else if self.nowCellX < self.actionWidth, self.nowCellX > self.swipeWidth {
                        
                        self.swipeOn()
                    } else {
                        
                        
                        switch self.swipeStatus {
                            
                        case .on:
                            
                            self.swipeOff()
                        case .off:
                            
                            if self.nowCellX == 0 {
                                
                                self.swipeOff()
                            } else {
                                
                                self.swipeOn()
                            }
                        }
                    }
                    
                    self.isShock = false
                    
                default:
                    break
                }
            })
            .disposed(by: cellDeinitDisposedBag)
        
        copy.rx.event
            .subscribe(onNext: { [weak self] panGestureRecognizer in
                guard let self = self else { return }
                
                if self.isEditing {
                    
                    return
                }
                
                switch panGestureRecognizer.state {
                    
                case .began:
                    
                    if self.nowCellX == 0 {
                        
                        SwipeManager.shared.swipeOff()
                    }
                    self.swipeLeftView.isHidden = false
                case .changed:
                    
                    let transLationX = panGestureRecognizer.translation(in: self).x
                    let moveX = self.nowGesX - transLationX
                    self.nowGesX = transLationX
                    let newX: CGFloat = self.swipebackCardView.frame.origin.x - moveX
                    
                    let resultX: CGFloat
                    
                    if newX < 0 {
                        
                        resultX = 0
                    } else {
                        
                        resultX = newX
                    }
                    
                    self.swipebackCardView.changeLeft(to: resultX)
                    
                    if self.nowCellX > self.actionWidth, !self.isShock {
                        
                        //MARK: 震動
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.prepare()
                        generator.impactOccurred()
                        self.isShock = true
                        
                    } else if self.nowCellX < self.actionWidth, self.isShock {
                        
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.prepare()
                        generator.impactOccurred()
                        self.isShock = false
                    }
                    
                case .ended:
                    if self.nowCellX > self.actionWidth {
                        
                        //MARK: swipe 行動
                        self.swipeAction()
                    } else if self.nowCellX < self.actionWidth, self.nowCellX > self.swipeWidth {
                        
                        self.swipeOn()
                    } else {
                        
                        
                        switch self.swipeStatus {
                            
                        case .on:
                            
                            self.swipeOff()
                        case .off:
                            
                            if self.nowCellX == 0 {
                                
                                self.swipeOff()
                            } else {
                                
                                self.swipeOn()
                            }
                        }
                    }
                    
                    self.isShock = false
                    
                default:
                    break
                }
            }).disposed(by: cellDeinitDisposedBag)
        
        gestView.addGestureRecognizer(ges)
        swipeLeftView.addGestureRecognizer(copy)
    }
    private let cellDeinitDisposedBag: DisposeBag = .init()
    
    let baseTokenView: BaseTokenListView = .init(frame: .zero)
    
    private let issuerTextField: UITextField = {
        
        let textField = UITextField()
        textField.font = .pingFangSemiBoldFont(size: 18)
        textField.textColor = .tokenListIssuerColor
        textField.isUserInteractionEnabled = true
        return textField
    }()
    
    private let nameTextField: UITextField = {
        
        let textField = UITextField()
        textField.font = .pingFangMediumFont(size: 15)
        textField.textColor = .tokenListCellTextFieldColor
        textField.isUserInteractionEnabled = true
        return textField
    }()
    
    private let countTimeLabel: UILabel = {
        
        let label = UILabel()
        label.setFont(.avenirHeavyFont(size: 11))
            .setTextColor(.tokenListTimerColor)
            .setTextAlignment(.center)
        return label
    }()
    
    private let tapGetPasswordButton: UIButton = {
        
        let button = UIButton()
        button.setImage(.noSmsRefresh, for: .normal)
        return button
    }()
    
    private let backCardView: UIView = {
        
        let view = NeverClearColorView()
        view.setBackgroundColor(.tokenListBackCardColor)
        return view
    }()
    
    private let deletedButton: UIButton = {
        
        let button = UIButton()
        return button
    }()
    
    private let deletedButtonInContentView: UIButton = {
        
        let button = UIButton()
        return button
    }()
    
    private let deleteImageView: UIImageView = .init(image: .noSmsNoSelected)
    
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
        addSwipeLeft()
        NotificationCenter.default.addObserver(self, selector: #selector(self.choseAllNotificationIdentifier(notification:)), name: Notification.Name("ChoseAllNotificationIdentifier"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.otpNotificationIdentifier(notification:)), name: Notification.Name("OTPNotificationIdentifier"), object: nil)
        
    }
    
    @objc func choseAllNotificationIdentifier(notification: Notification) {
        if let isSelectAll = notification.userInfo?["selectAll"] as? Bool {
            if isSelectAll {
                baseTokenView.selectImageView.image = UIImage(named: "NoSMS_groupAddSelect")
            } else {
                baseTokenView.selectImageView.image = UIImage(named: "NoSMS_oval")
            }
        }
    }
    
    @objc func otpNotificationIdentifier(notification: Notification) {
        
        let name = notification.userInfo?["name"] as? String
        let isSelect = notification.userInfo?["isSelect"] as? Bool ?? false
        let accountName = "[\(baseTokenView.issuerLabel.text!)] \(nameTextField.text!)"
        let token = notification.userInfo?["token"] as? Data
        let viewModelToken = viewModel?.tokenID
        if token == viewModelToken {
            if isSelect {
                baseTokenView.selectImageView.image = UIImage(named: "NoSMS_groupAddSelect")
            } else {
                baseTokenView.selectImageView.image = UIImage(named: "NoSMS_oval")
            }
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let swipebackCardView: UIView = {
        
        let view = NeverClearColorView()
        view.setBackgroundColor(.tokenListBackCardColor)
        return view
    }()
    
    private func layoutView() {
        
        addSubview(backCardView)
        sendSubviewToBack(backCardView)
        contentView.addSubview(deletedButtonInContentView)
        backCardView.addSubview(swipebackCardView)
        swipebackCardView.addSubview(baseTokenView)
        contentView.addSubview(nameTextField)
        contentView.addSubview(issuerTextField)
        swipebackCardView.addSubview(circleView)
        circleView.addSubview(countTimeLabel)
        contentView.addSubview(tapGetPasswordButton)
        swipebackCardView.addSubview(pinImageView)
        addSubview(deleteImageView)
        addSubview(deletedButton)
        baseTokenView.snp.makeConstraints {
            
            $0.edges.equalToSuperview()
        }
        
        deleteImageView.snp.makeConstraints {
            
            $0.centerY.equalTo(baseTokenView.passwordLabel)
            $0.right.equalTo(contentView.snp.left)
            $0.height.equalTo(ScaleWidth(at: 27))
            $0.width.equalTo(ScaleWidth(at: 27))
        }
        
        deletedButtonInContentView.snp.makeConstraints {
            
            $0.top.bottom.left.equalToSuperview()
            $0.right.equalTo(contentView).offset(20)
        }
        
        issuerTextField.snp.makeConstraints {
            
            $0.left.centerY.equalTo(baseTokenView.issuerLabel).offset(1)
            $0.right.equalTo(ScaleWidth(at: -16))
        }
        
        let textFieldUnderLineIssuer = UIView()
        textFieldUnderLineIssuer.setBackgroundColor(.tokenListCellTextFieldUnderLineColor)
        issuerTextField.addSubview(textFieldUnderLineIssuer)
        textFieldUnderLineIssuer.snp.makeConstraints {
            
            $0.left.right.equalToSuperview()
            $0.bottom.equalTo(ScaleWidth(at: 4))
            $0.height.equalTo(1)
        }
        
        nameTextField.snp.makeConstraints {
            
            $0.left.centerY.equalTo(baseTokenView.nameLabel).offset(1)
            $0.right.equalTo(ScaleWidth(at: -16))
        }
        
        let textFieldUnderLine = UIView()
        textFieldUnderLine.setBackgroundColor(.tokenListCellTextFieldUnderLineColor)
        nameTextField.addSubview(textFieldUnderLine)
        textFieldUnderLine.snp.makeConstraints {
            
            $0.left.right.equalToSuperview()
            $0.bottom.equalTo(ScaleWidth(at: 4))
            $0.height.equalTo(1)
        }
        
        backCardView.snp.makeConstraints {
            
            $0.top.left.width.equalToSuperview()
            $0.bottom.equalTo(ScaleWidth(at: -4))
        }
        
        swipebackCardView.snp.makeConstraints {
            
            $0.top.left.width.equalTo(contentView)
            $0.bottom.equalTo(contentView).offset(ScaleWidth(at: -4))
        }
        
        countTimeLabel.snp.makeConstraints {
            
            $0.center.equalTo(circleView)
        }
        
        circleView.snp.makeConstraints {
            
            $0.size.equalTo(ScaleWidth(at: 27))
            $0.centerY.equalTo(baseTokenView.nameLabel)
            $0.right.equalTo(ScaleWidth(at: -16))
        }
        
        tapGetPasswordButton.snp.makeConstraints {
            
            $0.edges.equalTo(circleView)
        }
        
        pinImageView.snp.makeConstraints {
            
            $0.top.equalTo(baseTokenView.issuerLabel)
            $0.right.equalTo(swipebackCardView).offset(ScaleWidth(at: -16))
            $0.size.equalTo(ScaleWidth(at: 30))
        }
        
        nameTextField.delegate = self
        issuerTextField.delegate = self
    }
    func runBackCardAnimation() {
        UIView.animate(withDuration: 0.3, animations: {
            
            self.swipebackCardView.backgroundColor = .tokenListBackcardAnimationColor
            
        }, completion: { (value: Bool) in
            UIView.animate(withDuration: 0.1, animations: {
                
                self.swipebackCardView.backgroundColor = .tokenListBackCardColor
            })
        })
    }
    func setBackCardAnimationColor(){
        
        for i in 1...3 {
            
            let asyncTime:Double = Double(i) * 0.4
            DispatchQueue.main.asyncAfter(deadline: .now() + asyncTime) { [weak self] in
                
                self?.runBackCardAnimation()
            }
        }
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if string.isEmpty {
            
            return true
        }
        
        if (textField.text?.count ?? 0) + string.count > MustAuth.issuerAndAccountLimit {
            
            return false
        } else {
            
            return true
        }
    }
    
    
    var viewModel: TokenListTableViewCellViewModelProtocol?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        moveImageView.removeFromSuperview()
        viewModel = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        //MARK: 在編輯狀態時切換模式的時候原生的圖片又跑出來了把它拿掉
        for view in self.subviews {
            
            if view.description.contains("UITableViewCellReorderControl") {
                
                let imageOfReorder = view.subviews[0] as? UIImageView
                imageOfReorder?.image = nil
            }
        }
    }
    
    private func changeLayout() {
        
        UIView.animate(withDuration: 0.1, animations: {
            
            self.baseTokenView.nameLabel.isHidden = self.isEditing
            self.baseTokenView.issuerLabel.isHidden = self.isEditing
            self.baseTokenView.passwordLabel.isHidden = self.isEditing
            self.nameTextField.isHidden = !self.isEditing
            self.issuerTextField.isHidden = !self.isEditing
            self.deletedButton.isEnabled = self.isEditing
            self.deletedButtonInContentView.isEnabled = self.isEditing
            self.baseTokenView.digitsView.isHidden = !self.isEditing
            self.deleteImageView.isHidden = !self.isEditing
            
            if self.isOnTime {
                
                self.circleView.isHidden = self.isEditing
                self.tapGetPasswordButton.isHidden = true
                self.baseTokenView.digitsView.isHidden = !self.isEditing
            } else {
                self.circleView.isHidden = true
                self.tapGetPasswordButton.isHidden = self.isEditing
                
                if !self.isEditing && !self.hotpShowPassword {
                    
                    self.baseTokenView.digitsView.isHidden = false
                    self.baseTokenView.passwordLabel.isHidden = true
                }
            }
            
        }, completion: nil)
        
        if isEditing {
            
            for view in self.subviews {
                
                if view.description.contains("UITableViewCellReorderControl") {
                    
                    let imageOfReorder = view.subviews[0] as? UIImageView
                    imageOfReorder?.image = nil
                    view.addSubview(moveImageView)
                    moveImageView.center = .init(x: ScaleWidth(at: 10), y: baseTokenView.passwordLabel.center.y)
                    
                    view.isHidden = isInSearch || (viewModel?.isPin ?? false)
                }
            }
            
            baseTokenView.digitsView.setColor(.tokenListHidePasswordInEditColor)
            
            //MARK: 為了在顯示的時候藏起來
            swipeLeftView.isHidden = true
            
            pinImageView.snp.remakeConstraints {
                
                $0.top.equalTo(baseTokenView.issuerLabel)
                $0.right.equalTo(self).offset(ScaleWidth(at: -16))
                $0.size.equalTo(ScaleWidth(at: 30))
            }
        } else {
            
            moveImageView.removeFromSuperview()
            baseTokenView.digitsView.setColor(.tokenListHidePasswordColor)
            
            pinImageView.snp.remakeConstraints {
                
                $0.top.equalTo(baseTokenView.issuerLabel)
                $0.right.equalTo(swipebackCardView).offset(ScaleWidth(at: -16))
                $0.size.equalTo(ScaleWidth(at: 30))
            }
        }
        
        resetPinStatus()
    }
    
    //MARK: 偷懶
    func resetPinStatus() {
        
        pinImageView.isHidden = !(viewModel?.isPin ?? false)
        swipeLabel.text = viewModel?.isPin ?? false ? "取消置顶" : "置顶"
        swipeImageView.image = viewModel?.isPin ?? false ? UIImage.noSMStokenListPinRemoveAction : UIImage.noSMStokenListPinAction
        
        let isPinColor = viewModel?.isPin ?? false ? UIColor.tokenListCellBackCardPinColor : UIColor.tokenListBackCardColor
        swipebackCardView.backgroundColor = isPinColor
        backCardView.backgroundColor = isPinColor
        if isShareOTP == true {
            pinImageView.isHidden = true
            tapGetPasswordButton.isHidden = true
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: true)
        changeLayout()
        if baseTokenView.passwordLabel.alpha == 0 {
            self.baseTokenView.digitsView.isHidden = false
            baseTokenView.digitsView.setColor(.tokenListHidePasswordInEditColor)
        }
    }
    
    override func bindData(viewModel: ViewModel) {
        super.bindData(viewModel: viewModel)
        
        baseTokenView.bindData(viewModel: viewModel)
        viewModel.name.bind(to:nameTextField.rx.text)
            .disposed(by: disposedBag)
        viewModel.issuer.bind(to: issuerTextField.rx.text)
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
        
        
        let isOnTime = viewModel.isOnTime
        baseTokenView.passwordLabel.setTextColor(.tokenListPasswordColor)
        
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
        
        deletedButtonInContentView.rx.tap.subscribe(onNext: { [weak self, weak haveSeletToDelete] in
            
            guard let self = self else { return }
            self.deletedButton.isSelected = !self.deletedButton.isSelected
            haveSeletToDelete?.onNext(self.deletedButton.isSelected)
        }).disposed(by: disposedBag)
        
        nameTextField.rx.controlEvent(.editingDidEnd)
            .flatMapLatest({[unowned self] in return self.nameTextField.rx.text.orEmpty })
            .bind(to: viewModel.name)
            .disposed(by: disposedBag)
        
        issuerTextField.rx.controlEvent(.editingDidEnd)
            .flatMapLatest({[unowned self] in return self.issuerTextField.rx.text.orEmpty })
            .bind(to: viewModel.issuer)
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
        
        viewModel.warningTime.map({ $0 ? UIColor.circleViewWarningColor : UIColor.circleViewNormalColor })
            .bind(to: countTimeLabel.rx.textColor, circleView.loadingColorBinder)
            .disposed(by: disposedBag)
        
        viewModel.isInSearch.subscribe(onNext: { [weak self] isInSearch in
            guard let self = self else { return }
            self.isInSearch = isInSearch
            self.changeLayout()
            
        }).disposed(by: disposedBag)
        
        self.viewModel = viewModel
    }
    
    override func willTransition(to state: UITableViewCell.StateMask) {
        super.willTransition(to: state)
        
        if state == .showingEditControl {
            
            swipeOff()
        }
    }
}
