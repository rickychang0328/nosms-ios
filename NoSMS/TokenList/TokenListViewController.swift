
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
            
    init(navigationItemViewModel: BaseNavigaitonItemProtocol = BaseNavigaitonItem(title: .init(value: "身份验证器")),
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
                self.sectionItems.rowItems = viewModels
                self.eventResult.onNext(.reloadData)
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
            
            let a = self.tokenStore.persistentTokensBehavior
                .map({$0[index]})
                .flatMapLatest({$0.password})
                .subscribe(onNext: { string in

                    UIPasteboard.general.string = string
                    
                    anyObserver.onNext(string)
                    anyObserver.onCompleted()
                }, onError: { error in
                    
                    anyObserver.onError(error)
                })
            return Disposables.create { a.dispose() }
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
            .setFont(.pingFangLightFont(size: 15))
            .setNumberOfLine(0)
            .setTextColor(.white)
        return label
    }()
    
    private let button: UIButton = {
       
        let button = UIButton()
        button.setTitle("开始设置", for: .normal)
        button.addCornerAndBorder(backgroundColor: .clear, cornerRadius: ScaleWidth(at: 6), masksToBounds: false, borderColor: .homePageBorderColor, borderWidth: 1)
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
        button.rx.tap.subscribe { [weak self] _ in
                   
            guard let self = self else { return }
            self.showAddTokenAlert()
                   
        }.disposed(by: disposedBag)
        
        let barBtn = UIBarButtonItem(customView: button)
        return barBtn
    }()

    private lazy var beforeEditTableViewBarButton: UIBarButtonItem = {

        let button = UIButton(type: UIButton.ButtonType.custom)
        button.setImage(.noSmsEdit, for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
        button.rx.tap
            .subscribe { [weak self] _ in
            guard let self = self else { return }
            self.tableView.setEditing(true, animated: true)
            self.navigationItem.rightBarButtonItems = [self.inEditTableViewBarButton]
        }.disposed(by: disposedBag)
        
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
        
        button.setTitle("刪除", for: .normal)
        button.backgroundColor = .warninglColor
        button.setTitleColor(.white, for: .normal)
        button.addCornerRadius(at: ScaleWidth(at: 6))
        return button
    }()
    
    private let homePageView: HomePageView = .init(frame: .zero)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(homePageView)
        
        homePageView.snp.makeConstraints {
            
            $0.top.equalTo(view.snp.topMargin)
            $0.left.right.bottomMargin.equalToSuperview()
        }
        
        homePageView.tapButtonEvent.subscribe { [weak self] _ in
            
            guard let self = self else { return }
            self.showAddTokenAlert()
        }.disposed(by: disposedBag)
        
        view.addSubview(bottomView)
        bottomView.addSubview(deleteTokenButton)
        bottomViewSetup()
                
        let leftbarItem = UIBarButtonItem(image: .noSmsMore, style: .plain, target: nil, action: nil)
                
        navigationItem.leftBarButtonItem = leftbarItem
        
        inEditTableViewBarButton.rx.tap
            .subscribe { [weak self] _ in
                guard let self = self else { return }
            
                self.tableView.setEditing(false, animated: true)
                self.tableView.endEditing(true)
                self.viewModel.tableViewEndEdit()
                self.wantToShowHomePageOrNot()
        }.disposed(by: disposedBag)
    
        navigationItem.rightBarButtonItems = [beforeEditTableViewBarButton, addTokenBarButton]
        
        viewModel.eventResult.subscribe { [weak self] _ in
            
            self?.tableView.reloadData()
            self?.wantToShowHomePageOrNot()
        }.disposed(by: disposedBag)
        
        tableView.rx.itemMoved
            .map({($0.sourceIndex.row, $0.destinationIndex.row)})
            .subscribe(onNext: self.viewModel.swapToken)
            .disposed(by: disposedBag)
        
        tableView.rx.itemSelected
            .map({ $0.row })
            .flatMapLatest(self.viewModel.selectItem)
            .subscribe(onNext: { [weak self] _ in
            
                self?.showErrorAlert(title: "成功複製")
            }, onError: { [weak self] error in
            
                self?.showErrorAlert(title: "複製失敗")
            }, onDisposed: { [weak self] in
                    
                self?.showErrorAlert(title: "Disposed")
            }).disposed(by: disposedBag)

        tableView.backgroundColor = .backgroudColor
    }
    
    private func wantToShowHomePageOrNot() {
        
        if viewModel.cellViewModels[0].numberOfRow == 0 {
                   
            navigationItem.rightBarButtonItems = []
            homePageView.isHidden = false
            
            if tableView.isEditing {
                
                tableView.setEditing(false, animated: true)
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
        
        deleteTokenButton.rx.tap.subscribe({ [weak self] _ in
            
            self?.showDeleteAlert()
        }).disposed(by: disposedBag)
    }
   
    private func showPastedStringAlert(pastedString: String) {
        
        let alertVC = UIAlertController(title: "是否要通过此验证码进行添加", message: pastedString, preferredStyle: .alert)
        
        let goPastedAlertAction = UIAlertAction(title: "前往添加", style: .default) { [weak self] _ in
            
            guard let self = self else { return }
            self.showKeyinTokenVC(string: pastedString)
        }
      
        let cancelAlertAction = UIAlertAction(title: "取消", style: .cancel) { [weak alertVC] _ in
            
            alertVC?.dismiss(animated: true, completion: nil)
        }
        
        alertVC.addAction(goPastedAlertAction)
        alertVC.addAction(cancelAlertAction)
        
        present(alertVC, animated: true, completion: nil)
    }
    
    private func showAddTokenAlert() {
        
        let alertVC = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let goPhotoeAlertAction = UIAlertAction(title: "相册选取扫描", style: .default) { [weak self] _ in
            
            guard let self = self else { return }
            self.showPhoto()
        }
        
        let goTokenScannerAlertAction = UIAlertAction(title: "扫描二维码", style: .default) { [weak self] _ in
            
            guard let self = self else { return }
            self.showTokenScannerVC()
        }
        
        let goKeyinAddTokenAlertAction = UIAlertAction(title: "手动输入验证码", style: .default) { [weak self] _ in
            
            guard let self = self else { return }
            self.showKeyinTokenVC()
        }
        
        let cancelAlertAction = UIAlertAction(title: "取消", style: .cancel) { [weak alertVC] _ in
            
            alertVC?.dismiss(animated: true, completion: nil)
        }
        
        alertVC.addAction(goPhotoeAlertAction)
        alertVC.addAction(goTokenScannerAlertAction)
        alertVC.addAction(goKeyinAddTokenAlertAction)
        alertVC.addAction(cancelAlertAction)
        
        present(alertVC, animated: true, completion: nil)
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
        
        let alertVC = UIAlertController(title: nil, message: "删除此账号并不会影响已设置的身份验证功能\n您可能因此无法登录自己的帐号", preferredStyle: .alert)
        let cancelAlertAction = UIAlertAction(title: "取消", style: .cancel) { [weak alertVC] _ in
            alertVC?.dismiss(animated: true, completion: nil)
        }
        let deleteAlertAction = UIAlertAction(title: "删除帐号", style: .default) { [weak self] _ in
            
            self?.viewModel.deleteToken()
        }
        alertVC.addAction(cancelAlertAction)
        alertVC.addAction(deleteAlertAction)
        present(alertVC, animated: true, completion: nil)
    }
}

extension Reactive where Base: UITableView {
    
    var isEditing: Binder<Bool> {
        
        return Binder<Bool>(self.base) { view, isEdit in
            
            view.isEditing = isEdit
        }
    }
}
