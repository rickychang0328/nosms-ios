//
//  FaceIDSettingViewController.swift
//  NoSMS
//
//  Created by azure on 2020/4/13.
//

import UIKit
import RxSwift
import BiometricAuthentication

protocol FaceIDSettingVCViewModelProtocol: BaseTableViewVCViewModelProtocol {
}
class FaceIDSettingVCViewModel: BaseVCViewModel, FaceIDSettingVCViewModelProtocol {
    
    var tableViewSectionItem: FaceIDSettingVCTableViewSectionItems
    
    var cellViewModels: [BaseTableViewSectionItemsProtocol] {
        
        return [tableViewSectionItem]
    }
    var tableViewStyle: UITableView.Style{return .grouped}
    
    init() {
        let title = BioMetricAuthenticator.shared.touchIDAvailable() ? "指纹解锁" : "面容ID解锁"
//        print("is faceid available:\(BioMetricAuthenticator.shared.touchIDAvailable())")
        tableViewSectionItem = FaceIDSettingVCTableViewSectionItems(title:title)
        super.init(navigationItem: BaseNavigaitonItem(title: .init(value: title)), backgroundColor: .faceIDSettingVCBackgroundColor)
    }
    
}
protocol FaceIDSettingVCTableViewSectionItemsProtocol: BaseTableViewSectionItemsProtocol{
    var switchItem:FaceIDSettingCellSwitchItems { get }
}
class FaceIDSettingVCTableViewSectionItems: FaceIDSettingVCTableViewSectionItemsProtocol {
    var switchItem: FaceIDSettingCellSwitchItems
    
    var settingItem:FaceIDSettingTableViewCellViewModel
    let sectionHeaderViewModel: BaseTableViewSectionHeaderFooterViewModelProtocol? = nil
    
    let sectionFooterViewModel: BaseTableViewSectionHeaderFooterViewModelProtocol? = nil
    
//    let switchItem:FaceIDSettingCellSwitchItems
    var numberOfRow: Int {
        
        return rowItems.count
    }
    init(isFaceID:Bool = true,title:String) {
//        if isFaceID {
//            settingItem =
            settingItem = FaceIDSettingTableViewCellViewModel(isFaceID: isFaceID)
//        }
        switchItem = FaceIDSettingCellSwitchItems(title:title)
        rowItems = [settingItem,switchItem]
    }
    subscript(index: Int) -> BaseTableViewCellViewModelProtocol {
        
        rowItems[index]
    }
    
    var rowItems: [BaseTableViewCellViewModelProtocol] = []
}
class FaceIDSettingTableViewCellViewModel: BaseTableViewCellViewModelProtocol {
    
    let baseCellItem: BaseTableViewCellViewModelItemProtocol = BaseTableViewCellViewModelItem(cellSelectionStyle: .init(value: .none), cellHeight:150, cellBackgroundColor: .init(value: .clear), cellContentViewBGColor: .init(value: .clear))
    
    var cellFactoryType: TableViewCellFactoryType { return .faceIDSettingTableViewCell(viewModel: self)}
        
//    let title: BehaviorSubject<String?>
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
            .setFont(.pingFangMediumFont(size: 15))
//            .setTextColor(.white)
            .setTextColor(.black)
            .setNumberOfLine(0)
        label.text = "开启后，可使用指纹解锁验证，快速完成登录指纹解锁仅对本机有效"
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
        
        layoutIfNeeded()
//        viewModel.title.bind(to: titleLabel.rx.text).disposed(by: disposedBag)
        
//        viewModel.getImage(targetSize: .init(width: titleImageView.bounds.width * 3, height: titleImageView.bounds.height * 3))
//            .bind(to: titleImageView.rx.image)
//            .disposed(by: disposedBag)
//
//        viewModel.photoCount.bind(to: countLabel.rx.text).disposed(by: disposedBag)
        
//        viewModel.isSelected.map({!$0}).bind(to: selectedImageView.rx.isHidden).disposed(by: disposedBag)
    }
}
protocol FaceIDSettingCellSwitchItemsProtocol: BaseTableViewCellViewModelProtocol {
    
    var title: String { get }
    var switcher: BehaviorSubject<Bool> { get }
    var authSuccess: BehaviorSubject<Bool>{get}
    var submitFaceIDSetting:BehaviorSubject<Bool> {get}
    var authError: BehaviorSubject<AuthenticationError> {get}
}

class FaceIDSettingCellSwitchItems: FaceIDSettingCellSwitchItemsProtocol {
    
    let switcher: BehaviorSubject<Bool> = .init(value: false)
    let authSuccess: BehaviorSubject<Bool> = .init(value: false)
    let submitFaceIDSetting: BehaviorSubject<Bool>  = .init(value:false)
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
    let authError: PublishSubject<AuthenticationError> = .init()
    let authSuccess: PublishSubject<Bool> = .init()
    let submitFaceIDSetting:PublishSubject<Bool> = .init()
    var isFirstOpen:Bool = true
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
//            $0.centerY.equalToSuperview()
            $0.top.equalTo(ScaleWidth(at: 20))
            $0.left.equalTo(ScaleWidth(at: 20))
            $0.bottom.equalTo(ScaleWidth(at: -20))
        }
        
        switchView.snp.makeConstraints {
            $0.top.equalTo(ScaleWidth(at: 17.5))
            $0.width.equalTo(ScaleWidth(at: 50))
            $0.height.equalTo(ScaleWidth(at: 25))
//            $0.centerY.equalTo(titleLabel)
            $0.right.equalTo(ScaleWidth(at: -35))
        }
    }
    
    override func bindData(viewModel: ViewModel) {
        super.bindData(viewModel: viewModel)
        
        titleLabel.text = viewModel.title
        viewModel.authError.bind(to: self.authError).disposed(by: disposedBag)
        viewModel.submitFaceIDSetting.bind(to: self.submitFaceIDSetting).disposed(by: disposedBag)
        viewModel.authSuccess.bind(to: self.authSuccess).disposed(by: disposedBag)
        viewModel.switcher.bind(to: switchView.rx.isOn).disposed(by: disposedBag)
        switchView.rx.controlEvent(.valueChanged)
        .withLatestFrom(switchView.rx.value)
        .subscribe(onNext : { bool in
            // this is the value of mySwitch
            print("is ON:\(bool)")
//            if self.isFirstOpen {
//                self.isFirstOpen = false
//                viewModel.authSuccess.bind(to: self.authSuccess).disposed(by: self.disposedBag)
//            }
            if bool {
                if !BioMetricAuthenticator.shared.faceIDAvailable() && !BioMetricAuthenticator.shared.touchIDAvailable() {
                    self.authSuccess.onNext(false)
                    viewModel.authSuccess.onNext(false)
                }else{
                    ///您要允许"MustAuth"使用面容ID/指纹吗？
                    self.submitFaceIDSetting.onNext(true)
                    viewModel.submitFaceIDSetting.onNext(true)
//                    BioMetricAuthenticator.authenticateWithBioMetrics(reason: "") { [weak self] (result) in
//
//                            switch result {
//                            case .success( _):
//                                // authentication successful
//        //                        self?.showLoginSucessAlert()
//                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                                    self?.authSuccess.onNext(true)
//
//                                }
//                            case .failure(let error):
//                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//                                    self?.authError.onNext(error)
//                                }
//                            }
//                    }
                }
                
            }
            
        })
        .disposed(by: disposedBag)
        
        switchView.rx.isOn
            .distinctUntilChanged()
            .bind(to: viewModel.switcher)
            .disposed(by: disposedBag)

    }
    
}

class FaceIDSettingViewController : BaseTableViewController<FaceIDSettingVCViewModel> {
    var isFirstOpen:Bool = true
   convenience init() {
        let viewModel = FaceIDSettingVCViewModel()
        self.init(viewModel: viewModel)
   }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewModel.tableViewSectionItem.switchItem.authSuccess.subscribe(onNext: { [weak self] success in
               guard let self = self else { return }
            if self.isFirstOpen {
                self.isFirstOpen = false
                return
            }
               if success {
                   //跳出辨識成功或是沒有動作
                
               }else {
                self.showAlert(title: "您的设备尚未开启面容ID识别，请稍后再试",
                          message: nil, confirmTitle: "确定",
                          confirmAction: { [weak self] in

                })
            }
           }).disposed(by: disposedBag)
        self.viewModel.tableViewSectionItem.switchItem.authError.subscribe(onNext: { [weak self] error in
            guard let self = self else { return }
            switch error{
                case .biometryLockedout:
                    self.showPasscodeAuthentication(message: error.message())
                default:
                    break
            }
        }).disposed(by: disposedBag)
        /**
         submitFaceIDSetting
         **/
        self.viewModel.tableViewSectionItem.switchItem.submitFaceIDSetting.subscribe(onNext: { [weak self] success in
            guard let self = self else { return }
            if success {
                self.showAlert(title: "", message: "您要允许\"MustAuth\"使用面容ID/指纹吗？", confirmTitle: "确认", cancelTitle: "取消", confirmAction: { [weak self] in
                        BioMetricAuthenticator.authenticateWithBioMetrics(reason: "") { [weak self] (result) in
                                
                            switch result {
                            case .success( _):
                                if !UserDefaults.standard.bool(forKey: UserDefaults.Key.faceIDString.faceIDString) {
                                    UserDefaults.standard.set(true, forKey: UserDefaults.Key.faceIDString.faceIDString)
                                }
                                // authentication successful
//                                self?.showLoginSucessAlert()
                               break
                            case .failure(let error):
                                
                                switch error {
                                    
                                // device does not support biometric (face id or touch id) authentication
                                case .biometryNotAvailable:
                                    self?.showErrorAlert(message: error.message())
                                    
                                // No biometry enrolled in this device, ask user to register fingerprint or face
                                case .biometryNotEnrolled:
//                                    self?.showGotoSettingsAlert(message: error.message())
                                    break
                                // show alternatives on fallback button clicked
                                case .fallback:
//                                    self?.txtUsername.becomeFirstResponder() // enter username password manually
                                    break
                                    // Biometry is locked out now, because there were too many failed attempts.
                                // Need to enter device passcode to unlock.
                                case .biometryLockedout:
                                    self?.showPasscodeAuthentication(message: error.message())
                                    
                                // do nothing on canceled by system or user
                                case .canceledBySystem, .canceledByUser:
                                    break
                                    
                                // show error for any other reason
                                default:
                                    self?.showErrorAlert(message: error.message())
                                }
                            }
                        }
                }, cancelAction: nil)
             
            }else {
//             self.showAlert(title: "您的设备尚未开启面容ID识别，请稍后再试",
//                       message: nil, confirmTitle: "确定",
//                       confirmAction: { [weak self] in
//
//             })
         }
        }).disposed(by: disposedBag)
        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    // show passcode authentication
        func showPasscodeAuthentication(message: String) {
            
            BioMetricAuthenticator.authenticateWithPasscode(reason: message) { [weak self] (result) in
                switch result {
                case .success( _):
    //                self?.showLoginSucessAlert() // passcode authentication success
                    break
                case .failure(let error):
                    print(error.message())
                }
            }
        }
}

