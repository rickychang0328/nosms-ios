//
//  FaceIDSettingViewController.swift
//  NoSMS
//
//  Created by azure on 2020/4/13.
//

import UIKit
import RxSwift
import BiometricAuthentication
import LocalAuthentication
import RxCocoa

public enum FaceIDAuthenticationStatus{
    case success
    case error
    case closeAuthentication
    case openAuthentication
    case others
}

enum AuthIDStatusManager {
    
    static var isLockWindow: Bool = false
    static var isAuthOpen: Bool { return UserDefaults.standard.bool(forKey: UserDefaults.Key.faceIDString.string) }
    static var systemAuthIsOpen: Bool { return BioMetricAuthenticator.shared.faceIDAvailable() || AuthIDStatusManager.touchIDAvailable() }
    static var lastInAppTime: Date = .init()
    static var isGoInSettingPageBefore: Bool { return UserDefaults.standard.bool(forKey: UserDefaults.Key.isFirstSetFaceID.string) }
    
    static var authMessage: String {
        
        return "请使用\(authType)解锁"
    }
    
    static var authManyTimeMessage: String {
        
        return "为\"MustAuth\"输入密码\n\(authType)验证短时间内失败多次，需要验证手机密码"
    }
    
    static var authType: String {
        
        return BioMetricAuthenticator.shared.isFaceIdDevice() ? "面容ID" : "指纹"
    }
    
    static func backgroundTimerAction() {
        
        lastInAppTime = .init()
    }

    static func setAuthOpen(toOpen status: Bool) {
        
        UserDefaults.standard.set(status, forKey: UserDefaults.Key.faceIDString.string)
    }
    
    static func showIDAuthPage(inVC: UIViewController, sucessHandler: (() -> Void)? = nil, systemIsNotOpenHandler: (() -> Void)? = nil) {
        
        if BioMetricAuthenticator.shared.faceIDAvailable() || AuthIDStatusManager.touchIDAvailable() {
            
            let faceIDHandler = {
                
                    BioMetricAuthenticator.authenticateWithPasscode(reason: AuthIDStatusManager.authManyTimeMessage, cancelTitle: "取消") { (result) in
                        
                        switch result {
                            
                        case .success:
                            
                            sucessHandler?()
                            AuthIDStatusManager.isLockWindow = false
                        case .failure:
                            
                            break
                        }
                    }
                }
            if BioMetricAuthenticator.shared.isFaceIdDevice() {
                
                faceIDHandler()
            } else {
                
                BioMetricAuthenticator.authenticateWithBioMetrics(reason: AuthIDStatusManager.authMessage, cancelTitle: "取消") { (result) in
                    
                    switch result {
                        
                    case .success:
                        sucessHandler?()
                        AuthIDStatusManager.isLockWindow = false
                    case .failure(let error):
                        
                        if error == .canceledByUser || error == .canceledBySystem {
                            
                        } else {
                            
                            faceIDHandler()
                        }
                    }
                }
            }
        } else {

            inVC.showAlertOneButton(title: "您的设备尚未开启\(AuthIDStatusManager.authType)识别，请稍后再试", actionTitle: "确定", confirmAction: systemIsNotOpenHandler)
        }
    }
    
    static func touchIDAvailable() -> Bool {
        
        let context = LAContext()
        var error: NSError?
        
        let canEvaluate = context.canEvaluatePolicy(LAPolicy.deviceOwnerAuthentication, error: &error)
        if #available(iOS 11.0, *) {
            return canEvaluate && context.biometryType == .touchID
        }
        return canEvaluate
    }
}

enum FaceIDSettingVCViewModelEvent {
    
    case goSetupGest
    case goSelectSettingGest
}

protocol FaceIDSettingVCViewModelProtocol: BaseTableViewVCViewModelProtocol {
    
    var idStyleTitle: String { get }
    var eventObservable: Observable<FaceIDSettingVCViewModelEvent> { get }

    func setIsUseAuthID(_ isUse: Bool)
    func selectCell(at indexPath: IndexPath)
}

private let kFaceID = "面容ID"
private let kTouchID = "指纹解锁"

class FaceIDSettingVCViewModel: BaseVCViewModel, FaceIDSettingVCViewModelProtocol {
    
    private let eventPublisher: PublishSubject<FaceIDSettingVCViewModelEvent> = .init()
    
    var eventObservable: Observable<FaceIDSettingVCViewModelEvent> { return eventPublisher.asObservable()}
    
    func selectCell(at indexPath: IndexPath) {
        let viewModel = cellViewModels[indexPath.section][indexPath.row]
        guard viewModel === tableViewSectionItem.gestSettingTableViewCellViewModel else { return }
        
        if GestVerificationManager.isOpen {
             
            eventPublisher.onNext(.goSelectSettingGest)
        } else {
            
            eventPublisher.onNext(.goSetupGest)
        }
    }
    
    let idStyleTitle: String
    
    let tableViewSectionItem: FaceIDSettingVCTableViewSectionItems
    
    var cellViewModels: [BaseTableViewSectionItemsProtocol] {
        
        return [tableViewSectionItem]
    }
    var tableViewStyle: UITableView.Style{return .grouped}
    
    init() {
        let title = BioMetricAuthenticator.shared.isFaceIdDevice() ? "\(kFaceID)解锁" : "\(kTouchID)"
        self.idStyleTitle = title
        tableViewSectionItem = FaceIDSettingVCTableViewSectionItems(isFaceID: BioMetricAuthenticator.shared.isFaceIdDevice(), title: title)
        super.init(navigationItem: BaseNavigaitonItem(title: .init(value: "安全设置")), backgroundColor: .faceIDSettingVCBackgroundColor)
    }
    
    func setIsUseAuthID(_ isUse: Bool) {
        
        tableViewSectionItem.switchItem.switcher.onNext(isUse)
    }
}

protocol FaceIDSettingVCTableViewSectionItemsProtocol: BaseTableViewSectionItemsProtocol{
    
    var switchItem: FaceIDSettingCellSwitchItems { get }
    var gestSettingTableViewCellViewModel: GestSettingTableViewCellViewModelType { get }
}

class FaceIDSettingVCTableViewSectionItems: FaceIDSettingVCTableViewSectionItemsProtocol {
    
    let switchItem: FaceIDSettingCellSwitchItems
    let gestSettingTableViewCellViewModel: GestSettingTableViewCellViewModelType
    let sectionHeaderViewModel: BaseTableViewSectionHeaderFooterViewModelProtocol? = nil
    
    let sectionFooterViewModel: BaseTableViewSectionHeaderFooterViewModelProtocol? = nil
    
    var numberOfRow: Int {
        
        return rowItems.count
    }
    
    init(isFaceID: Bool, title: String) {
        
        gestSettingTableViewCellViewModel = GestSettingTableViewCellViewModel()
        switchItem = FaceIDSettingCellSwitchItems(title:title)
        rowItems = [switchItem, gestSettingTableViewCellViewModel]
    }
    
    subscript(index: Int) -> BaseTableViewCellViewModelProtocol {
        
        rowItems[index]
    }
    
    let rowItems: [BaseTableViewCellViewModelProtocol]
}
class FaceIDSettingTableViewCellViewModel: BaseTableViewCellViewModelProtocol {
    
    let baseCellItem: BaseTableViewCellViewModelItemProtocol = BaseTableViewCellViewModelItem(cellSelectionStyle: .init(value: .none), cellHeight: ScaleWidth(at: 190), cellBackgroundColor: .init(value: .clear), cellContentViewBGColor: .init(value: .clear))
    
    var cellFactoryType: TableViewCellFactoryType { return .faceIDSettingTableViewCell(viewModel: self)}
        
    var isFaceID: Bool
    
    internal init(isFaceID: Bool) {
        
        self.isFaceID = isFaceID
    }
}
class FaceIDSettingTableViewCell: BaseTableViewCell<FaceIDSettingTableViewCellViewModel> {
    
    private let titleImageView: UIImageView = {
        let imageView: UIImageView = .init()
        imageView.layer.masksToBounds = true
        imageView.image = .noSmsFaceID
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label: UILabel = .init()
        label.setTextAlignment(.center)
            .setFont(.pingFangMediumFont(size: 14))
            .setTextColor(.faceIDSettingHeaderTextColor)
            .setTextAlignment(.left)
            .setNumberOfLine(0)
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        addSubview(titleImageView)
        addSubview(titleLabel)
        
        titleImageView.snp.makeConstraints {
            
            $0.top.equalTo(ScaleWidth(at: 40))
            $0.size.equalTo(ScaleWidth(at: 50))
            $0.centerX.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(titleImageView.snp.bottom).offset(20)
            $0.left.equalTo(54.5)
            $0.right.equalTo(-40)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func bindData(viewModel: FaceIDSettingTableViewCellViewModel) {
        super.bindData(viewModel: viewModel)
        
        let idStyleIsFaceID = viewModel.isFaceID ? kFaceID : kTouchID
        titleImageView.image = viewModel.isFaceID ? .noSmsFaceID : .noSmsFingerPrint
        titleLabel.text = "开启后，可使用\(idStyleIsFaceID)验证，快速完成登录\(idStyleIsFaceID)仅对本机有效"
    }
}
protocol FaceIDSettingCellSwitchItemsProtocol: BaseTableViewCellViewModelProtocol {
    
    var title: String { get }
    var switcher: BehaviorSubject<Bool> { get }
    var authStatus: BehaviorSubject<FaceIDAuthenticationStatus>{get}
    var authError: BehaviorSubject<AuthenticationError> {get}
}

class FaceIDSettingCellSwitchItems: FaceIDSettingCellSwitchItemsProtocol {
    
    let switcher: BehaviorSubject<Bool> = .init(value: false)
    let authStatus: BehaviorSubject<FaceIDAuthenticationStatus> = .init(value: .others)
    let authError: BehaviorSubject<AuthenticationError> = .init(value: .other)
    let title: String
    
    let baseCellItem: BaseTableViewCellViewModelItemProtocol
    
    var cellFactoryType: TableViewCellFactoryType { .faceIDSwitcherTableViewCell(viewModel: self) }

    internal init(title: String,
                  baseCellItem: BaseTableViewCellViewModelItemProtocol = BaseTableViewCellViewModelItem(cellSelectionStyle: .init(value: .none),
                                                                                                        cellHeight: 60,
                                                                                                        cellBackgroundColor: .init(value: .clear),
                                                                                                        cellContentViewBGColor: .init(value: .faceIDSettingBackgroundColor))) {
        
        self.title = title
        self.baseCellItem = baseCellItem
    }
}
class FaceIDSettingSwitchTableViewCell<ViewModel: FaceIDSettingCellSwitchItemsProtocol>: BaseTableViewCell<ViewModel> {

    private let titleLabel: UILabel = {
        
        let label = UILabel()
        label.setTextColor(.faceIDSettingTextColor)
            .setFont(.pingFangSemiBoldFont(size: 14))
        return label
    }()
    
    private let switchView: UISwitch = {
        
        let switchView = UISwitch()
        switchView.onTintColor = .manuallyTOTPSwitchColor
        return switchView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        layoutView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func layoutView() {
        
        addSubview(titleLabel)
        addSubview(switchView)
        
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(ScaleWidth(at: 20))
            $0.left.equalTo(ScaleWidth(at: 20))
            $0.bottom.equalTo(ScaleWidth(at: -20))
        }
        
        switchView.snp.makeConstraints {
            $0.top.equalTo(ScaleWidth(at: 17.5))
            $0.width.equalTo(ScaleWidth(at: 50))
            $0.height.equalTo(ScaleWidth(at: 25))
            $0.right.equalTo(ScaleWidth(at: -35))
        }
    }
    
    override func bindData(viewModel: ViewModel) {
        super.bindData(viewModel: viewModel)
        
        titleLabel.text = viewModel.title
        
        viewModel.switcher.bind(to: switchView.rx.isOn).disposed(by: disposedBag)
        switchView.rx.controlEvent(.valueChanged)
            .withLatestFrom(switchView.rx.value)
            .subscribe(onNext : { bool in
            
                if bool {
                    if !BioMetricAuthenticator.shared.faceIDAvailable() && !AuthIDStatusManager.touchIDAvailable() {
                        
                        viewModel.authStatus.onNext(.error)
                    } else {
                        
                        viewModel.authStatus.onNext(.openAuthentication)
                    }
                } else {
                    
                    viewModel.authStatus.onNext(.closeAuthentication)
                }
            }).disposed(by: disposedBag)
        
        switchView.isOn = UserDefaults.standard.bool(forKey: UserDefaults.Key.faceIDString.string)
        switchView.rx.isOn
            .distinctUntilChanged()
            .bind(to: viewModel.switcher)
            .disposed(by: disposedBag)

    }
    
}

class FaceIDSettingViewController : BaseTableViewController<FaceIDSettingVCViewModel> {
    let authTitle = BioMetricAuthenticator.shared.isFaceIdDevice() ? "面容ID" : "指纹解锁"
    
    
    convenience init() {
        let viewModel = FaceIDSettingVCViewModel()
        self.init(viewModel: viewModel)
    }
        
    private func authResult(isOpened: Bool) {
        
        let title = isOpened ? "已关闭" : "已开启"
        
        let contentView: UIView = navigationController?.view ?? view
        NoSMSHUD.showToast(title: "\(self.authTitle)\(title)", contentView: contentView,toastSecond: 2)
        UserDefaults.standard.set(!isOpened, forKey: UserDefaults.Key.faceIDString.string)
    }
    
    func goSelectSettingGest() {
        
        let viewModel = GestVerificationOpenedMeunViewControllerViewModel { coordinator in
            switch coordinator {
            
            case .popToBeforeVC:
                
                self.navigationController?.popToViewController(self, animated: true)
            }
        }
        let vc = GestVerificationOpenedMeunViewController(viewModel: viewModel)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func goSetupGest() {
        
        let viewModel = GestVerificationSettingViewControllerViewModel { [weak self] coordinator in
            guard let self = self else { return }
            switch coordinator {
            
            case .settingPasswordDone:
                self.navigationController?.popToViewController(self, animated: true)
                NoSMSHUD.showToast(title: "手势解锁已开启")
            }
        }
        let vc = GestVerificationSettingViewController(viewModel: viewModel)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rx.itemSelected
            .subscribe(onNext: viewModel.selectCell(at:))
            .disposed(by: disposedBag)
        viewModel.eventObservable
            .subscribe(onNext: { [weak self] event in
                guard let self = self else { return }
                switch event {
                
                case .goSelectSettingGest:
                    
                    self.goSelectSettingGest()
                case .goSetupGest:
                    
                    self.goSetupGest()
                }
            }).disposed(by: disposedBag)
        
        self.viewModel.tableViewSectionItem.switchItem.authStatus.subscribe(onNext: { [weak self] status in
            guard let self = self else { return }
            
            switch status {
                   //跳出辨識成功或是沒有動作
            case .closeAuthentication:
                
                if AuthIDStatusManager.touchIDAvailable() || BioMetricAuthenticator.shared.faceIDAvailable() {
                    
                    self.showPasscodeAuthentication()
                } else {
                    
                    self.authResult(isOpened: true)
                }
            case .openAuthentication:
                
                self.showAlert(title: "",
                               message: "您要允许\"MustAuth\"使用\(self.authTitle)吗？",
                                confirmTitle: "好",
                                cancelTitle: "不允许", confirmAction: {
                    
                    self.showPasscodeAuthentication()
                                        
                }, cancelAction: {
                    
                    self.viewModel.setIsUseAuthID(false)
                })
            case .error:
                
                self.showAlertOneButton(title: "您的设备尚未开启\(AuthIDStatusManager.authType)识别，请稍后再试",
                                        actionTitle: "确定",
                                        confirmAction: {
                                            
                                            UserDefaults.standard.set(false, forKey: UserDefaults.Key.faceIDString.string)
                                            self.viewModel.setIsUseAuthID(false)
                })
                break
            case .success:
                break
            default:
                break
                
            }
        }).disposed(by: disposedBag)
    }
    
    func showPasscodeAuthentication() {
        
        let blur = BlurViewController.shared
        blur.reset()
        
        blur.modalPresentationStyle = .overFullScreen
        present(blur, animated: false) {
            
            let lastIDisOpened = AuthIDStatusManager.isAuthOpen
            
            let faceIDHandler = {
                BioMetricAuthenticator.authenticateWithPasscode(reason: AuthIDStatusManager.authManyTimeMessage,
                                                                cancelTitle: "取消") { [weak self] (result) in
                    guard let self = self else { return }
                    switch result {
                    case .success:
                        
                        self.authResult(isOpened: lastIDisOpened)
                    case .failure:
                        
                        self.viewModel.setIsUseAuthID(lastIDisOpened)
                    }
                    blur.dismiss(animated: false)
                }
            }
            
            if BioMetricAuthenticator.shared.isFaceIdDevice() {
                
                faceIDHandler()
            } else {
                
                BioMetricAuthenticator.authenticateWithBioMetrics(reason: AuthIDStatusManager.authMessage, cancelTitle: "取消") { (result) in
                    
                    switch result {
                        
                    case .success:
                        
                        self.authResult(isOpened: lastIDisOpened)
                        blur.dismiss(animated: false)
                    case .failure(let error):
                        
                        switch error {
                            
                        case .canceledByUser, .canceledBySystem:
                            
                            self.viewModel.setIsUseAuthID(lastIDisOpened)
                            blur.dismiss(animated: false)
                        default:
                            
                            faceIDHandler()
                        }
                    }
                }
            }
        }
    }
    
    //MARK: 為了補上面空的位子
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return ScaleWidth(at: 15)
    }
}

