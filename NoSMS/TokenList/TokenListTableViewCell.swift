
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
        self.issuer = issuer.map({
            if $0.isEmpty {
                
                return " "
            } else {
                
                return $0
            }
        })
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
        
        addSubview(issuerLabel)
        addSubview(passwordLabel)
        addSubview(nameLabel)
        addSubview(digitsView)
        
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
        digitsView.isHidden = true
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func bindData(viewModel: BaseTokenListViewType) {
        disposedBag = .init()
        //MARK: 給空白讓 label 的 auto 高不會跑掉
        let name = viewModel.name.map({ string -> String in
          
            if string.isEmpty {
                
                return " "
            } else {
                
                return string
            }
        })
            
        name.bind(to: nameLabel.rx.text)
            .disposed(by: disposedBag)

        viewModel.issuer
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
    var issuer: Observable<String> { get }
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
        
        contentView.addSubview(swipeLeftView)
        swipeLeftView.snp.makeConstraints {
            
            $0.top.width.bottom.equalTo(swipebackCardView)
            $0.right.equalTo(swipebackCardView.snp.left)
        }

        let tapGest = UITapGestureRecognizer()
        tapGest.rx.event.subscribe(onNext: { [weak self] tapGest in
            self?.swipeAction()
            
            }).disposed(by: cellDeinitDisposedBag)
        swipeLeftView.addGestureRecognizer(tapGest)
        
        let gestView = UIView()
        contentView.addSubview(gestView)
        
        gestView.snp.makeConstraints {
            
            $0.top.left.bottom.equalTo(swipebackCardView)
            $0.width.equalTo(ScaleWidth(at: 50))
        }
        
        swipeLeftView.addSubview(swipeViewSubView)
        
        swipeViewSubView.snp.makeConstraints {
            
            $0.edges.equalToSuperview()
        }
         
        let ges = UIPanGestureRecognizer()
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
                        
                        let generator = UIImpactFeedbackGenerator(style: .light)
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
                                
                                return
                            }
                            self.swipeOn()
                        }
                    }

                default:
                    break
                }
            })
            .disposed(by: cellDeinitDisposedBag)
        gestView.addGestureRecognizer(ges)
    }
    private let cellDeinitDisposedBag: DisposeBag = .init()
    
    private let baseTokenView: BaseTokenListView = .init(frame: .zero)

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
        backCardView.addSubview(swipebackCardView)
        swipebackCardView.addSubview(baseTokenView)
        contentView.addSubview(nameTextField)
        swipebackCardView.addSubview(circleView)
        circleView.addSubview(countTimeLabel)
        swipebackCardView.addSubview(tapGetPasswordButton)
        swipebackCardView.addSubview(pinImageView)
        addSubview(deleteImageView)
        addSubview(deletedButton)
        baseTokenView.snp.makeConstraints {
            
            $0.edges.equalToSuperview()
        }
        
        deleteImageView.snp.makeConstraints {
            
            $0.centerY.equalTo(baseTokenView.passwordLabel)
            $0.right.equalTo(contentView.snp.left)
            $0.height.equalTo(ScaleWidth(at: 18))
            $0.width.equalTo(ScaleWidth(at: 18))
        }
        
        deletedButton.snp.makeConstraints {
            
            $0.top.bottom.left.equalToSuperview()
            $0.right.equalTo(contentView.snp.left).offset(20)
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
    
    
    private var viewModel: TokenListTableViewCellViewModelProtocol?
    
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
            self.baseTokenView.passwordLabel.isHidden = self.isEditing
            self.nameTextField.isHidden = !self.isEditing
            self.deletedButton.isEnabled = self.isEditing
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
        } else {
            
            moveImageView.removeFromSuperview()
            baseTokenView.digitsView.setColor(.tokenListHidePasswordColor)
        }
        
        pinImageView.isHidden = !(viewModel?.isPin ?? false) || isInSearch || isEditing
        swipeLabel.text = viewModel?.isPin ?? false ? "取消置顶" : "置顶"
        swipeImageView.image = viewModel?.isPin ?? false ? UIImage.noSMStokenListPinRemoveAction : UIImage.noSMStokenListPinAction

    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: true)
        
        changeLayout()
    }
    
    override func bindData(viewModel: ViewModel) {
        super.bindData(viewModel: viewModel)
        
        baseTokenView.bindData(viewModel: viewModel)
        viewModel.name.bind(to:nameTextField.rx.text)
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
