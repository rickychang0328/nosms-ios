
import UIKit
import RxSwift
import RxCocoa

enum TokenListViewModelEvent {
    
    case reloadData
    case error(Error)
}

protocol TokenListVCViewModelProtocol: BaseTableViewVCViewModelProtocol {
    
    var eventResult: BehaviorSubject<TokenListViewModelEvent> { get }
    var deleteIsEnable: Observable<Bool> { get }
    
    func deleteToken()
    func selectItem(index: Int) -> Observable<String>
    func swapToken(beforeIndex: Int, afterIndex: Int)
    func tableViewEndEdit()
}

protocol TokenListSectionItemProtocol: BaseTableViewSectionItemsProtocol {
    
    var rowItems: [BaseTableViewCellViewModelProtocol] { get set }
}

class TokenListSectionItem: TokenListSectionItemProtocol {
    
    var sectionHeaderViewModel: BaseTableViewSectionHeaderFooterViewModelProtocol?
    
    var sectionFooterViewModel: BaseTableViewSectionHeaderFooterViewModelProtocol?
    
    var numberOfRow: Int {
        
        return rowItems.count
    }
    
    var rowItems: [BaseTableViewCellViewModelProtocol] = []
    
    subscript(index: Int) -> BaseTableViewCellViewModelProtocol {
        
        return rowItems[index]
    }
}

class TokenListVCViewModel: BaseVCViewModel, TokenListVCViewModelProtocol {
    
    let deleteIsEnable: Observable<Bool>
  
    let eventResult: BehaviorSubject<TokenListViewModelEvent> = .init(value: .reloadData)

    var tableViewStyle: UITableView.Style {
        
        return .grouped
    }
    
    var cellViewModels: [BaseTableViewSectionItemsProtocol] {
        
        return [sectionItems]
    }
    
    private let sectionItems: TokenListSectionItemProtocol
    
    private let tokenStore: TokenStoreProtocol
            
    init(navigationItemViewModel: BaseNavigaitonItemProtocol = BaseNavigaitonItem(title: .init(value: "MustAuth")),
         tokenStore: TokenStoreProtocol = KeychainTokenStore.shared,
         backgroundColor: UIColor = .clear,
         sectionItems: TokenListSectionItemProtocol = TokenListSectionItem()) {
        
        self.tokenStore = tokenStore
        self.sectionItems = sectionItems
        self.deleteIsEnable = tokenStore.haveSelectTokenToDelete
        super.init(navigationItem: navigationItemViewModel, backgroundColor: backgroundColor)
        
        tokenStore.persistentTokensBehavior
            .map( {
                $0.map({
                    TableViewCellViewModelFactory.getCellViewModel(type: .tokenList($0))
                })
            })
            .subscribe(onNext: { [weak self] viewModels in
                guard let self = self else { return }
                
                //轉換變動不需要重新load, 不是新增 也不是刪除
                let count = self.sectionItems.rowItems.count
                self.sectionItems.rowItems = viewModels
                if count == viewModels.count {
                    
                    
                } else {
                                        
                    self.eventResult.onNext(.reloadData)
                }
            })
            .disposed(by: disposedBag)
    }
    
    func deleteToken() {
            
        do {
            try tokenStore.deleteSelectedToken()
        } catch {
            
            eventResult.onNext(.error(error))
        }
    }
    
    func swapToken(beforeIndex: Int, afterIndex: Int) {
        
        do {
            try tokenStore.moveTokenFromIndex(beforeIndex, toIndex: afterIndex)
        } catch {
            
            eventResult.onNext(.error(error))
        }
    }
    
    func selectItem(index: Int) -> Observable<String> {

        let observer: Observable<String> = .create { anyObserver -> Disposable in
            
            let disposed = self.tokenStore.persistentTokensBehavior
                .map({$0[index]})
                .subscribe(onNext: { adapterToken in
                    
                    let showPassword = try? adapterToken.passwordShow.value()
                    
                    if showPassword ?? true {
                        
                        UIPasteboard.general.string = adapterToken.persistentToken.token.currentPassword
                        
                        anyObserver.onNext("[ \(adapterToken.persistentToken.token.issuer) ]\n\(adapterToken.persistentToken.token.name)\n验证码已复制")
                        anyObserver.onCompleted()
                    } else {
                        
                        adapterToken.getOnTapPassword()
                        anyObserver.onCompleted()
                    }
                })
            return Disposables.create { disposed.dispose() }
        }
        return observer
    }
    
    func tableViewEndEdit() {
        
        tokenStore.resetTokenSelected()
    }
}

class HomePageView: UIView {
    
    private let logoImageView: UIImageView = .init(image: .noSmsLogo)
    
    private let descriptionLabel: UILabel = {
        
        let label = UILabel()
        
        label.setText("启用两步验证后，无论何时您登录账号，\n都需要输入自己的密码和此应用生成的验证码")
            .setTextAlignment(.center)
            .setFont(.pingFangMediumFont(size: 15))
            .setNumberOfLine(0)
            .setTextColor(.white)
        return label
    }()
    
    private let button: UIButton = {
       
        let button = UIButton()
        button.setTitle("开始设置", for: .normal)
        button.addCornerAndBorder(backgroundColor: .clear, cornerRadius: ScaleWidth(at: 6), masksToBounds: false, borderColor: .homePageBorderColor, borderWidth: 1)
        button.titleLabel?.font = .pingFangMediumFont(size: 15)
        return button
    }()
    
    var tapButtonEvent: ControlEvent<Void> {
        
        return button.rx.tap
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .countColor
        addSubview(logoImageView)
        addSubview(descriptionLabel)
        addSubview(button)
        
        logoImageView.snp.makeConstraints {
            
            $0.top.equalTo(ScaleWidth(at: 142.5))
            $0.left.equalTo(ScaleWidth(at: 121))
            $0.right.equalTo(ScaleWidth(at: -121))
            $0.height.equalTo(ScaleWidth(at: 146.5))
        }
        
        descriptionLabel.snp.makeConstraints {
            
            $0.centerX.equalTo(logoImageView)
            $0.top.equalTo(logoImageView.snp.bottom).offset(ScaleHeight(at: 67.5))
            $0.left.equalTo(ScaleWidth(at: 37.5))
            $0.right.equalTo(ScaleWidth(at: -37.5))
        }
        
        button.snp.makeConstraints {
            
            $0.centerX.equalTo(logoImageView)
            $0.left.equalTo(ScaleWidth(at: 20))
            $0.right.equalTo(ScaleWidth(at: -20))
            $0.bottom.equalTo(ScaleWidth(at: -54))
            $0.height.equalTo(ScaleWidth(at: 42))
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class TokenListViewController<VCViewModel: TokenListVCViewModelProtocol>: BaseTableViewController<VCViewModel> {
    
    private var lifeCycleDisposeBag: DisposeBag = .init()
    
    private lazy var addTokenBarButton: UIBarButtonItem = {

        let button = UIButton(type: UIButton.ButtonType.custom)
        button.setImage(.noSmsAdd, for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 40, height: 25)
        button.rx.tap.subscribe(onNext: { [weak self] _ in
                   
            guard let self = self else { return }
            self.choseHowToAddTokenView.showView()
                   
        }).disposed(by: disposedBag)
        
        let barBtn = UIBarButtonItem(customView: button)
        return barBtn
    }()

    private lazy var beforeEditTableViewBarButton: UIBarButtonItem = {

        let button = UIButton(type: UIButton.ButtonType.custom)
        button.setImage(.noSmsEdit, for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
        button.rx.tap
            .subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.tableView.setEditing(true, animated: true)
            self.navigationItem.leftBarButtonItem?.isEnabled = false
            self.navigationItem.rightBarButtonItems = [self.inEditTableViewBarButton]
        }).disposed(by: disposedBag)
        
        let barBtn = UIBarButtonItem(customView: button)
        return barBtn
    }()
    
    private let inEditTableViewBarButton: UIBarButtonItem = .init(image: .noSmsDone, style: .plain, target: nil, action: nil)
    
    private let bottomView: UIView = {
       
        let view = UIView()
        view.setBackgroundColor(.white)
        return view
    }()
    
    private let deleteTokenButton: UIButton = {
       
        let button = UIButton()
        
        button.setTitle("删除", for: .normal)
        button.backgroundColor = .warninglColor
        button.setTitleColor(.white, for: .normal)
        button.addCornerRadius(at: ScaleWidth(at: 6))
        return button
    }()
    
    private let homePageView: HomePageView = .init(frame: .zero)
    
    private let choseHowToAddTokenView: ChoseHowToAddTokenView = .init(frame: .zero)
    
    private let menuView: MenuView = .init(frame: .zero)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.layer.shadowColor = UIColor.black.withAlphaComponent(0.12).cgColor
        navigationController?.navigationBar.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        navigationController?.navigationBar.layer.shadowRadius = 4.0
        navigationController?.navigationBar.layer.shadowOpacity = 1.0
        navigationController?.navigationBar.layer.masksToBounds = false
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .any, barMetrics: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        
        view.addSubview(homePageView)
        navigationController?.view.addSubview(choseHowToAddTokenView)
        navigationController?.view.addSubview(menuView)
        
        
        homePageView.snp.makeConstraints {
            
            $0.top.equalTo(view.snp.topMargin)
            $0.left.right.bottomMargin.equalToSuperview()
        }
        
        choseHowToAddTokenView.snp.makeConstraints {
            
            $0.edges.equalToSuperview()
        }
        
        menuView.snp.makeConstraints {
            
            $0.edges.equalToSuperview()
        }
        
        choseHowToAddTokenView.chosePhoto.subscribe(onNext: { [weak self] event in
            guard let self = self else { return }
            
            switch event {
                
            case .photo:
                self.showPhoto()
            case .camera:
                self.showTokenScannerVC()
            case .keyIn:
                self.showKeyinTokenVC()
            }
        }).disposed(by: disposedBag)
        
        homePageView.tapButtonEvent.subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            
            self.choseHowToAddTokenView.showView()
        }).disposed(by: disposedBag)
        
        view.addSubview(bottomView)
        bottomView.addSubview(deleteTokenButton)
        bottomViewSetup()
                
        let leftbarItem = UIBarButtonItem(image: .noSmsMore, style: .plain, target: nil, action: nil)
                
        navigationItem.leftBarButtonItem = leftbarItem
        
        leftbarItem.rx.tap.subscribe(onNext: { [weak self] in
            
            self?.menuView.showView()
        }).disposed(by: disposedBag)
        
        inEditTableViewBarButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
            
                self.navigationItem.leftBarButtonItem?.isEnabled = true
                self.tableView.endEditing(true)
                self.tableView.setEditing(false, animated: true)
                self.viewModel.tableViewEndEdit()
                self.wantToShowHomePageOrNot()
                
        }).disposed(by: disposedBag)
    
        navigationItem.rightBarButtonItems = [beforeEditTableViewBarButton, addTokenBarButton]
        
        viewModel.eventResult.subscribe(onNext: { [weak self] _ in
            
            self?.tableView.reloadData()
            self?.wantToShowHomePageOrNot()
        }).disposed(by: disposedBag)
        
        tableView.rx.itemMoved
            .map({($0.sourceIndex.row, $0.destinationIndex.row)})
            .subscribe(onNext: self.viewModel.swapToken)
            .disposed(by: disposedBag)
        
        tableView.rx.itemSelected
            .map({ $0.row })
            .flatMapLatest(self.viewModel.selectItem)
            .subscribe(onNext: { [weak self] string in
            
                NoSMSHUD.showToast(title: string)
            }).disposed(by: disposedBag)

        tableView.backgroundColor = .backgroudColor
        
        menuView.choseEvent.subscribe(onNext: { [weak self] event in
            
            guard let self = self else { return }
            let nextVC = event.nextVC
            
            self.navigationController?.pushViewController(nextVC, animated: true)
            
        }).disposed(by: disposedBag)
    }
    
    private func wantToShowHomePageOrNot() {
        
        if viewModel.cellViewModels[0].numberOfRow == 0 {
                   
            navigationItem.rightBarButtonItems = []
            homePageView.isHidden = false
            
            if tableView.isEditing {
                
                tableView.setEditing(false, animated: true)
                navigationItem.leftBarButtonItem?.isEnabled = true
                self.viewModel.tableViewEndEdit()
                
                self.deleteTokenButton.isEnabled = false
                self.bottomView.isHidden = true
                self.bottomView.snp.remakeConstraints {
                                       
                    $0.bottom.left.right.equalToSuperview()
                    $0.height.equalTo(0)
                }
            }
            
        } else {
                   
            if tableView.isEditing {
                
               
            } else {
                
                navigationItem.rightBarButtonItems = [beforeEditTableViewBarButton, addTokenBarButton]
                homePageView.isHidden = true
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        wantToShowHomePageOrNot()
        
        viewModel.intoAppPastedAction.subscribe(onNext: { [weak self] pastedString in
                   
            self?.showPastedStringAlert(pastedString: pastedString)
        }).disposed(by: lifeCycleDisposeBag)
        
        NotificationCenter.default.rx
           .notification(UIWindow.keyboardWillShowNotification)
           .compactMap({$0.userInfo})
           .compactMap({$0[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect})
           .map({$0.height})
           .subscribe(onNext: { [weak self] height in
                guard let self = self else { return }
                if self.isFirstResponder {
                    UIView.animate(withDuration: 0.1) {
                                      
                        self.tableView.changeBottom(to: -height)
                        self.view.layoutIfNeeded()
                    }
                }
           }).disposed(by: lifeCycleDisposeBag)
       
        NotificationCenter.default.rx
            .notification(UIWindow.keyboardWillHideNotification)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
              
                UIView.animate(withDuration: 0.1) {
                  
                    self.tableView.changeBottom(to: 0)
                    self.view.layoutIfNeeded()

                }
          }).disposed(by: lifeCycleDisposeBag)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        lifeCycleDisposeBag = .init()
    }
    
    private func bottomViewSetup() {
        
        deleteTokenButton.snp.makeConstraints {
            
            $0.top.equalTo(ScaleWidth(at: 5))
            $0.left.equalTo(ScaleWidth(at: 20))
            $0.right.equalTo(ScaleWidth(at: -20))
            $0.height.equalTo(ScaleWidth(at: 42))
        }
        
        viewModel.deleteIsEnable.subscribe(onNext: { [weak self] canDelete in
            
            guard let self = self else { return }
                
            self.deleteTokenButton.isEnabled = canDelete
            self.bottomView.isHidden = !canDelete
            if canDelete {
                    
                self.bottomView.snp.remakeConstraints {
                        
                    $0.bottom.left.right.equalToSuperview()
                    $0.height.equalTo(ScaleWidth(at: 87))
                }
            } else {
                    
                self.bottomView.snp.remakeConstraints {
                        
                    $0.bottom.left.right.equalToSuperview()
                    $0.height.equalTo(0)
                }
            }
        }).disposed(by: disposedBag)
        
        deleteTokenButton.rx.tap.subscribe(onNext: { [weak self] _ in
            
            self?.showDeleteAlert()
        }).disposed(by: disposedBag)
    }
   
    private func showPastedStringAlert(pastedString: String) {
        
        showAlert(title: "是否要通过此验证码进行添加",
                  message: pastedString,
                  confirmTitle: "前往添加", confirmAction: { [weak self] in
            guard let self = self else { return }
            self.showKeyinTokenVC(string: pastedString)
        })
    }
    
    private func showKeyinTokenVC(string: String? = nil) {
        
        let nextVC = JoinManuallyTOTPTypeViewController(viewModel: JoinManuallyVCViewModel(pastedString: string))
        
        navigationController?.pushViewController(nextVC, animated: true)
    }
    
    private func showTokenScannerVC() {
        
        let status = AuthorizationManager.cameraStatus()
        
        if status == .restricted || status == .denied {
            
            self.showAlertToOpenSettingURL(title: "相机启用失败", message: "相机权限未开启")
        } else {
            
            let nextVC = TokenScannerViewController(viewModel: TokenScannerViewModel())
                 
            navigationController?.pushViewController(nextVC, animated: true)
        }
    }
    
    private func showPhoto() {
        
        let photoVC = UINavigationController(rootViewController: PhotoCheckViewController(viewModel: PhotoCheckVCViewModel()))
        photoVC.modalPresentationStyle = .overFullScreen
        
        AuthorizationManager.photoLiabraryStatus().drive(onNext: { status in
            
            if status == .authorized || status == .notDetermined {
                
                self.present(photoVC, animated: true, completion: nil)

            } else {
                
                self.showAlertToOpenSettingURL(title: "相簿读取失败", message: "相簿权限未开启")
            }
            }).disposed(by: disposedBag)
    }
    
    private func showAlertToOpenSettingURL(title: String?, message: String?) {
        
        let alertController = UIAlertController (title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "确认", style: .default, handler: nil)
        alertController.addAction(cancelAction)
        let settingsAction = UIAlertAction(title: "设定", style: .default) { _ in

            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }

            if UIApplication.shared.canOpenURL(settingsUrl) {
                
                UIApplication.shared.open(settingsUrl, completionHandler: nil)
            }
        }
        alertController.addAction(settingsAction)

        self.present(alertController, animated: true, completion: nil)
    }
    
    private func showDeleteAlert() {
        
        showAlert(title: "删除此账号并不会影响已设置的身份验证功能\n您可能因此无法登录自己的帐号",
                  message: nil, confirmTitle: "删除帐号",
                  confirmAction: { [weak self] in
                
            self?.viewModel.deleteToken()
        })
    }
}

extension Reactive where Base: UITableView {
    
    var isEditing: Binder<Bool> {
        
        return Binder<Bool>(self.base) { view, isEdit in
            
            view.isEditing = isEdit
        }
    }
}
