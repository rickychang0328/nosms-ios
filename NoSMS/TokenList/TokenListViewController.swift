
import UIKit
import RxSwift
import RxCocoa

enum TokenListViewModelEvent {
    
    case reloadData
    case resetSearch
    case scrollToIndex(Int)
    case error(Error)
    case empty
}

protocol TokenListVCViewModelProtocol: BaseTableViewVCViewModelProtocol {
    
    var eventResult: BehaviorSubject<TokenListViewModelEvent> { get }
    var deleteIsEnable: Observable<Bool> { get }
    var tokenIsEmpty: Bool { get }

    func deleteToken()
    func selectItem(index: Int) -> Observable<String>
    func swapToken(beforeIndex: Int, afterIndex: Int)
    func tableViewEndEdit()
    func searchText(input: String)
    func viewDidAppear()
}

protocol TokenListSectionItemProtocol: BaseTableViewSectionItemsProtocol {
    
    var rowItems: [TokenListTableViewCellViewModelProtocol] { get set }
    
    func setSearchString(input: String)
    func getRealIndex(afterSearchIndex: Int) -> Int
    func isSameString(input: String) -> Bool
}

class TokenListSectionItem: TokenListSectionItemProtocol {
    
    private struct AfterSearchViewModel {
        
        let tokenListItem: TokenListTableViewCellViewModelProtocol
        let realIndex: Int
    }
    
    private var searchString: String = .init()
    
    var sectionHeaderViewModel: BaseTableViewSectionHeaderFooterViewModelProtocol?
    
    var sectionFooterViewModel: BaseTableViewSectionHeaderFooterViewModelProtocol?
    
    var numberOfRow: Int {
  
        return searchItems.count
    }
    
    var rowItems: [TokenListTableViewCellViewModelProtocol] = [] {
        
        didSet {
            
            setSearchString(input: searchString)
        }
    }
    
    private var searchItems: [AfterSearchViewModel] = []
    
    subscript(index: Int) -> BaseTableViewCellViewModelProtocol {
        
        return searchItems[index].tokenListItem
    }
    
    // input 空的就會回到不搜索狀態
    func setSearchString(input: String) {
        
        searchString = input
        searchItems = []
    
        if input.isEmpty {
            
            for index in rowItems.indices {
                
                searchItems.append(AfterSearchViewModel(tokenListItem: rowItems[index], realIndex: index))
                rowItems[index].isInSearch.onNext(!input.isEmpty)
            }
        } else {
            
            for index in rowItems.indices {
                
                let disposble = Observable.combineLatest(rowItems[index].name, rowItems[index].issuer)
                    .map({ $0.0.lowercased().contains(input.lowercased()) ||
                        $0.1.lowercased().contains(input.lowercased())})
                    .subscribe(onNext: { sameSearch in
                        
                        if sameSearch {
                            
                            self.searchItems.append(
                                AfterSearchViewModel(tokenListItem: self.rowItems[index],
                                                     realIndex: index))
                            self.rowItems[index].isInSearch.onNext(!input.isEmpty)
                        } else {
                            
                            
                        }
                    })
                disposble.dispose()
            }
        }
    }
    
    func getRealIndex(afterSearchIndex: Int) -> Int {
        
        return searchItems[afterSearchIndex].realIndex
    }
    
    func isSameString(input: String) -> Bool {
        
        return input == searchString
    }
}

class TokenListVCViewModel: BaseVCViewModel, TokenListVCViewModelProtocol {
        
    var tokenIsEmpty: Bool {
        
        return tokenStore.tokenIsEmpty
    }
    
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
    
    private var isFirstOpen: Bool = true
            
    init(navigationItemViewModel: BaseNavigaitonItemProtocol = BaseNavigaitonItem(title: .init(value: "MustAuth")),
         tokenStore: TokenStoreProtocol = KeychainTokenStore.shared,
         backgroundColor: UIColor = .tokenListBackgroundColor,
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
            }).subscribe(onNext: { [weak self] viewModels in
                guard let self = self else { return }
                
                //轉換變動不需要重新load, 不是新增 也不是刪除
                let count = self.sectionItems.rowItems.count
                self.sectionItems.rowItems = viewModels
                if count == viewModels.count {
                    
                // 當變多的時候就增加成功 所以重置搜索狀態
                } else if count < viewModels.count {
                    
                  
                    self.eventResult.onNext(.resetSearch)
                    self.eventResult.onNext(.reloadData)
                    //初始化時就不觸發新增效果
                    
                    if self.isFirstOpen {
                        self.isFirstOpen = false
                        return
                    }
                    self.eventResult.onNext(.scrollToIndex(viewModels.count - 1))
                        
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
        
        let realIndex = sectionItems.getRealIndex(afterSearchIndex: index)

        let observer: Observable<String> = .create { anyObserver -> Disposable in
            
            let disposed = self.tokenStore.persistentTokensBehavior
                .map({$0[realIndex]})
                .subscribe(onNext: { adapterToken in
                    
                    let showPassword = try? adapterToken.passwordShow.value()
                    
                    if showPassword ?? true {
                        
                        UIPasteboard.general.string = try? adapterToken.password.value()
                        
                        anyObserver.onNext("[ \(adapterToken.token.issuer) ]\n\(adapterToken.token.name)\n验证码已复制")
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
    
    func searchText(input: String) {
        
        if sectionItems.isSameString(input: input) {
            
        } else {
            
            sectionItems.setSearchString(input: input)
            eventResult.onNext(.reloadData)
        }
    }
    func viewDidAppear() {
        eventResult.onNext(.empty)
    }
}

class HomePageView: UIView {
    
    private let logoImageView: UIImageView = {
        
        let imageView = UIImageView(image: .noSmsLogo)
        
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    private let descriptionLabel: UILabel = {
        
        let label = UILabel()
        
        label.setText("启用两步验证后，无论何时您登录账号，\n都需要输入自己的密码和此应用生成的验证码")
            .setTextAlignment(.center)
            .setFont(.pingFangMediumFont(size: 15))
            .setNumberOfLine(0)
            .setTextColor(.homePageTextColor)
        return label
    }()
    
    private let button: UIButton = {
       
        let button = UIButton()
        button.setTitle("开始设置", for: .normal)
        button.addCornerAndBorder(backgroundColor: .clear, cornerRadius: ScaleWidth(at: 6), masksToBounds: false, borderColor: .homePageButtonBroderColor, borderWidth: 1)
        button.titleLabel?.font = .pingFangMediumFont(size: 15)
        button.backgroundColor = .homePageButtonBackgroundColor
        
        return button
    }()
    
    var tapButtonEvent: ControlEvent<Void> {
        
        return button.rx.tap
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setCGColor()
    }
    
    private func setCGColor() {
  
        button.layer.borderColor = UIColor.homePageButtonBroderColor.cgColor
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .homePageBackgroundColor
        addSubview(logoImageView)
        addSubview(descriptionLabel)
        addSubview(button)
        
        logoImageView.snp.makeConstraints {
            
            $0.top.equalTo(ScaleWidth(at: 126.5))
            $0.left.equalTo(ScaleWidth(at: 97.5))
            $0.right.equalTo(ScaleWidth(at: -97.5))
            $0.height.equalTo(ScaleWidth(at: 180))
        }
        
        descriptionLabel.snp.makeConstraints {
            
            $0.centerX.equalTo(logoImageView)
            $0.top.equalTo(logoImageView.snp.bottom).offset(ScaleHeight(at: 50))
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

class TokenListViewController<VCViewModel: TokenListVCViewModelProtocol>: BaseTableViewController<VCViewModel>, UITextFieldDelegate, UIPopoverPresentationControllerDelegate {
    
    private var lifeCycleDisposeBag: DisposeBag = .init()
    let tokenListMenuVC:TokenListMenuViewController = .init(viewModel: TokenListMenuVCViewModel())
    
    private lazy var addTokenBarButton: UIBarButtonItem = {

        let button = UIButton(type: UIButton.ButtonType.custom)
        button.setImage(.noSmsAdd, for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 40, height: 25)
        button.rx.tap.subscribe(onNext: { [weak self] _ in
                   
            guard let self = self else { return }
//            self.choseHowToAddTokenView.showView()
            // 设置弹出的尺寸
//            self.tokenListMenuVC.providesPresentationContextTransitionStyle = true
//            self.tokenListMenuVC.definesPresentationContext = true
            self.tokenListMenuVC.preferredContentSize = CGSize(width: ScaleWidth(at: 144),height: ScaleWidth(at: 150))
            self.tokenListMenuVC.modalPresentationStyle = .popover
            var popover = self.tokenListMenuVC.popoverPresentationController!
            popover.delegate = self
            popover.popoverBackgroundViewClass = MyPopoverBackgroundView.self
//            popover.backgroundColor = .white
//            popover.backgroundColor = UIColor.init(white: 1, alpha: 1)
//            let view:UIImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 200, height: 165))
//            view.image = UIImage(named: "NoSMS_popBack")
            
//            popover.permittedArrowDirections = UIPopoverArrowDirection.init(rawValue: 0)
//            popover.permittedArrowDirections = .up
            popover.barButtonItem = self.addTokenBarButton
            self.present(self.tokenListMenuVC, animated: true)
//            self.present(self.tokenListMenuVC, animated: true, completion: {
//                 self.tokenListMenuVC.view.superview?.layer.cornerRadius = 5
////                self.tokenListMenuVC.view.superview?.clipsToBounds = false
//            })
            if self.searchTextField.isFirstResponder {
                              
                self.searchTextField.resignFirstResponder()
            }
                   
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
                if self.searchTextField.isFirstResponder {
                    
                    self.searchTextField.resignFirstResponder()
                }
                self.tableView.setEditing(true, animated: true)
                self.navigationItem.leftBarButtonItem?.isEnabled = false
                self.navigationItem.rightBarButtonItems = [self.inEditTableViewBarButton]
        }).disposed(by: disposedBag)
        
        let barBtn = UIBarButtonItem(customView: button)
        return barBtn
    }()
    
    private let inEditTableViewBarButton: UIBarButtonItem = .init(image: .noSmsDone, style: .plain, target: nil, action: nil)
    
    private lazy var leftBarButton: UIBarButtonItem = {

        let button = UIButton(type: UIButton.ButtonType.custom)
        button.setImage(.noSmsMore, for: .normal)
        button.frame = .init(x: 0, y: 0, width: 25, height: 25)
        button.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.menuView.showView()
                if self.searchTextField.isFirstResponder {
                                  
                    self.searchTextField.resignFirstResponder()
                }
            }).disposed(by: disposedBag)
        button.addSubview(self.updateRedView)
        let barBtn = UIBarButtonItem(customView: button)
        self.updateRedView.snp.makeConstraints{
            $0.width.height.equalTo(8)
            $0.top.equalTo(-2)
            $0.right.equalTo(5)
        }
        return barBtn
    }()
    
    private let updateRedView: UIView = {
        
        let view = UIView()
        view.frame = .init(x: 25, y: 0, width: 8, height: 8)
        view.setBackgroundColor(.mustAuthRedColor)
        .addCornerRadius(at: 4)
        return view
    }()
    
    private let bottomView: UIView = {
       
        let view = UIView()
        view.setBackgroundColor(.tokenListBottomViewBackgroundColor)
        return view
    }()
    
    private let deleteTokenButton: UIButton = {
       
        let button = UIButton()
        button.setTitle("删除", for: .normal)
        button.backgroundColor = .mustAuthRedColor
        button.setTitleColor(.white, for: .normal)
        button.addCornerRadius(at: ScaleWidth(at: 6))
        return button
    }()
    
    private let homePageView: HomePageView = .init(frame: .zero)
    
    private let choseHowToAddTokenView: ChoseHowToAddTokenView = .init(frame: .zero)
    
    private let menuView: MenuView = .init(frame: .zero)
    
    private lazy var searchTextField: UITextField = {
       
        let textField = UITextField()
        textField.textColor = .tokenListSearchTextFieldTextColor
        textField.backgroundColor = .tokenListSearchTextFieldBackgroundColor
        textField.placeholder = "搜索"
        textField.font = .pingFangMediumFont(size: 15)
        textField.addCornerRadius(at: ScaleWidth(at: 6))
        
        let leftViewWidth = ScaleWidth(at: 18)
        let leftPan = ScaleWidth(at: 14)
        let leftPanAdd = ScaleWidth(at: 10)
        let leftView = UIView(frame: CGRect(x: 0, y: 0, width: leftViewWidth + leftPan + leftPanAdd, height: leftViewWidth))
        let leftImageView = UIImageView(frame: CGRect(x: leftPan, y: 0, width: leftViewWidth, height: leftViewWidth))
        leftImageView.image = .noSmsSearch
        leftView.addSubview(leftImageView)
        textField.leftView = leftView
        textField.leftViewMode = .always
        
        let rightButtonWidth = ScaleWidth(at: 20)
        let rightPan = ScaleWidth(at: 8)
        let rightView = UIView(frame: CGRect(x: 0, y: 0, width: rightButtonWidth + rightPan, height: leftViewWidth))
        let clearButton = UIButton(frame: CGRect(x: 0, y: 0, width: rightButtonWidth, height: rightButtonWidth))
        clearButton.setImage(.noSmsDelete, for: .normal)
        rightView.addSubview(clearButton)
        textField.rightView = rightView
        textField.rightViewMode = .whileEditing
        textField.rx.text
            .compactMap({$0})
            .map({!($0.count > 0)})
            .bind(to: rightView.rx.isHidden)
            .disposed(by: self.disposedBag)
        clearButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                rightView.isHidden = true
                self.cleanTextField()
            }).disposed(by: self.disposedBag)
        textField.returnKeyType = .search
        
        textField.delegate = self
        return textField
    }()
    
    private let resetSearchButton: UIButton = {
        
        let button = UIButton()
        button.setTitle("取消", for: .normal)
        button.setTitleColor( .countColor, for: .normal)
        button.titleLabel?.font = .pingFangMediumFont(size: 15)
        button.isHidden = true
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.layer.shadowColor = UIColor.black.withAlphaComponent(0.12).cgColor
        navigationController?.navigationBar.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        navigationController?.navigationBar.layer.shadowRadius = 4.0
        navigationController?.navigationBar.layer.shadowOpacity = 1.0
        navigationController?.navigationBar.layer.masksToBounds = false
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .any, barMetrics: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        
        view.addSubview(searchTextField)
        view.addSubview(resetSearchButton)
        view.addSubview(homePageView)
        navigationController?.view.addSubview(choseHowToAddTokenView)
        navigationController?.view.addSubview(menuView)
        
        searchTextField.snp.makeConstraints {
            
            $0.top.equalToSuperview().offset(ScaleWidth(at: 8))
            $0.left.equalToSuperview().offset(ScaleWidth(at: 12))
            $0.right.equalTo(ScaleWidth(at: -12))
            $0.height.equalTo(ScaleWidth(at: 40))
        }
        
        resetSearchButton.snp.makeConstraints {
            
            $0.top.bottom.equalTo(searchTextField)
            $0.right.equalToSuperview().offset(ScaleWidth(at: -12))
        }
        
        view.addSubview(bottomView)
        
        bottomView.addSubview(deleteTokenButton)
        bottomViewSetup()

        tableView.snp.remakeConstraints {
            
            $0.top.equalTo(searchTextField.snp.bottom).offset(ScaleWidth(at: 8))
            $0.left.right.equalToSuperview()
            $0.bottom.equalTo(bottomView.snp.top)
        }
        
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
                        
        navigationItem.leftBarButtonItem = leftBarButton
            
        inEditTableViewBarButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
            
                self.navigationItem.leftBarButtonItem?.isEnabled = true
                if self.searchTextField.isFirstResponder {
                                  
                    self.searchTextField.resignFirstResponder()
                }
                self.tableView.endEditing(true)
                self.tableView.setEditing(false, animated: true)
                self.viewModel.tableViewEndEdit()
                self.wantToShowHomePageOrNot()
                
            }).disposed(by: disposedBag)
    
        navigationItem.rightBarButtonItems = [beforeEditTableViewBarButton, addTokenBarButton]

        tableView.rx.itemMoved
            .map({($0.sourceIndex.row, $0.destinationIndex.row)})
            .subscribe(onNext: self.viewModel.swapToken)
            .disposed(by: disposedBag)
        tableView.rx.itemMoved.subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            
            //MARK: tableview 拖曳的各種坑盡量 reloadData 保持正常
            self.tableView.reloadData()
        }).disposed(by: disposedBag)
        
        tableView.rx.itemSelected
            .map({ $0.row })
            .flatMapLatest(self.viewModel.selectItem)
            .subscribe(onNext: { [weak self] string in
                guard self != nil else { return }
                NoSMSHUD.showToast(title: string)
            }).disposed(by: disposedBag)

        tableView.rx.didScrollToTop.subscribe(onNext: {[weak self] in
                guard let self = self else { return }
                if (self.searchTextField.text?.isEmpty ?? true){
                    self.showSearchTextAnimation()
                }
            }).disposed(by: disposedBag)

        tableView.rx.didScroll.subscribe { [weak self] _ in
            guard let self = self else { return }
            
            if (self.searchTextField.text?.isEmpty ?? true){
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.showSearchTextAction()
                }
            }
        }.disposed(by: disposedBag)
        tableView.backgroundColor = .tokenListTableViewBackgroundColor
        
        menuView.choseEvent.subscribe(onNext: { [weak self] event in
            
                guard let self = self else { return }
                let nextVC = event.nextVC
                
                self.navigationController?.pushViewController(nextVC, animated: true)
                
            }).disposed(by: disposedBag)
        
        searchTextField.rx.text
            .orEmpty
            .subscribe(onNext: viewModel.searchText)
            .disposed(by: disposedBag)
        
        resetSearchButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.resetSearch()
            }).disposed(by: disposedBag)


        self.tokenListMenuVC.choseToAddTokenView.chosePhoto.subscribe(onNext: { [weak self] event in
            guard let self = self else { return }
            self.tokenListMenuVC.dismiss(animated: false, completion: nil)
            
            switch event {
                
            case .photo:
                self.showPhoto()
            case .camera:
                self.showTokenScannerVC()
            case .keyIn:
                self.showKeyinTokenVC()
            }
        }).disposed(by: disposedBag)
        self.callVersionAPI()
        
    }
    private func showSearchTextAction(){
       
        if !self.searchTextField.isEditing && self.tableView.contentSize.height > self.tableView.frame.height {
            if self.tableView.panGestureRecognizer.translation(in: self.tableView).y < 0 || ( self.tableView.contentOffset.y > self.tableView.panGestureRecognizer.translation(in: self.tableView).y) {

                DispatchQueue.main.async {
                    
                    UIView.animate(withDuration: 0.3, delay: 0.0,
                                   usingSpringWithDamping: 1.0, initialSpringVelocity: 5.0,
                                   animations: {
                                    self.searchTextField.snp.updateConstraints{item in
                                        item.top.equalTo(ScaleWidth(at: 0))
                                        item.height.equalTo(ScaleWidth(at: 0))
                                    }
                                    self.searchTextField.isHidden = true
                                    self.view.layoutIfNeeded()
                    },
                                   completion: nil
                    )
                }
            }else {
                if self.tableView.contentOffset.y < 0 {
                    showSearchTextAnimation()
                }
            }
        }else {
            if self.tableView.contentOffset.y < 0 {
                showSearchTextAnimation()
            }
        }
    }
    private func showSearchTextAnimation(){
        
        DispatchQueue.main.async {
            
            UIView.animate(withDuration: 0.3, delay: 0.0,
                           usingSpringWithDamping: 1.0, initialSpringVelocity: 5.0,
                           animations: {
                            self.searchTextField.snp.updateConstraints{item in
                                item.top.equalTo(ScaleWidth(at: 8))
                                item.height.equalTo(ScaleWidth(at: 40))
                            }
                            self.searchTextField.isHidden = false
                            self.view.layoutIfNeeded()
            },
                           completion: nil
            )
        }
    }
    private func callVersionAPI(){
//        let repository = Repository(apiClient: APIClient())
        
        Repository.sharedInstance.postVersion {[weak self] (result) in
            switch result {
            case .success(let items):
                DispatchQueue.main.async {
                    self?.menuView.reloadTableViewData()
                    if items.isNeedUpdate ?? false {
                        self?.updateRedView.isHidden = false
                        
                    }else {
                        self?.updateRedView.isHidden = true
                    }
                }
                
            case .failure(_):

                DispatchQueue.main.async {
                        
                    self?.updateRedView.isHidden = true
                }
            }
        }
    }
    private func viewModelEventWorking(event: TokenListViewModelEvent) {
        
        switch event {
        case .reloadData:
            
            tableView.reloadData()
            wantToShowHomePageOrNot()
        case .resetSearch:
            tableView.reloadData()
            wantToShowHomePageOrNot()
            resetSearch()
        case .scrollToIndex(let rowIndex):
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {[weak self] in
                 guard let self = self else { return }
                self.tableView.reloadData()
                self.wantToShowHomePageOrNot()
                self.resetSearch()
                self.tableView.scrollToRow(at: IndexPath(row: rowIndex, section: 0), at: .bottom, animated: false)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.showSearchTextAction()
                    if let view = self.tableView.cellForRow(at: IndexPath(row: rowIndex, section: 0)) as? TokenListTableViewCell<TokenListTableViewCellViewModel> {
                        view.setBackCardAnimationColor()
                    }
                }
            }
            
        case .error(_):
            break
        case .empty:
            break
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField.isFirstResponder {
            
            textField.resignFirstResponder()
            setupViewInSearchStatus()
        }
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
        setupViewInSearchStatus()
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        
        setupViewInSearchStatus()
        if textField.text?.isEmpty ?? true {
            
            
        } else {
            
            searchTextField.layoutIfNeeded()
        }
    }
    
    private func setupViewInSearchStatus() {
        
        let textFieldWidth: CGFloat
        let resetSearchButtonIsHidden: Bool
        
        if !(searchTextField.text?.isEmpty ?? true) || searchTextField.isFirstResponder {
                
            textFieldWidth = ScaleWidth(at: -52)
            resetSearchButtonIsHidden = false
        } else {
            
            textFieldWidth = ScaleWidth(at: -12)
            resetSearchButtonIsHidden = true
        }
        
        searchTextField.changeRight(to: textFieldWidth)
        resetSearchButton.isHidden = resetSearchButtonIsHidden
    }
    
    private func cleanTextField() {
        
        searchTextField.text = ""
        viewModel.searchText(input: "")
    }
    
    private func resetSearch() {
        
        cleanTextField()
        if searchTextField.isFirstResponder {
            
            searchTextField.resignFirstResponder()
        }
        setupViewInSearchStatus()
    }
    
    private func wantToShowHomePageOrNot() {
        
        if viewModel.tokenIsEmpty {
                   
            navigationItem.rightBarButtonItems = []
            homePageView.isHidden = false
            
            if tableView.isEditing {
                
                tableView.setEditing(false, animated: true)
                navigationItem.leftBarButtonItem?.isEnabled = true
                self.viewModel.tableViewEndEdit()
                
                self.deleteTokenButton.isEnabled = false
                self.bottomView.isHidden = true
                self.bottomView.snp.updateConstraints {
                                       
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
        
       NotificationCenter.default.rx.notification(UIApplication.didEnterBackgroundNotification).subscribe({[weak self] _ in
                guard let self = self else { return }
    //            if self.tokenListMenuVC.isViewLoaded {
                    self.tokenListMenuVC.dismiss(animated: true, completion: nil)
    //            }
                }).disposed(by: lifeCycleDisposeBag)
        
        NotificationCenter.default.rx
           .notification(UIWindow.keyboardWillShowNotification)
           .compactMap({$0.userInfo})
           .compactMap({$0[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect})
           .map({$0.height})
           .subscribe(onNext: { [weak self] height in
                guard let self = self else { return }
                if UIApplication.shared.applicationState == .active  {
                    UIView.animate(withDuration: 0.1) {
                                      
                        self.bottomView.changeBottom(to: -height)
                        self.view.layoutIfNeeded()
                    }
                }
           }).disposed(by: lifeCycleDisposeBag)
       
        NotificationCenter.default.rx
            .notification(UIWindow.keyboardWillHideNotification)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
              
                UIView.animate(withDuration: 0.1) {
                  
                    self.bottomView.changeBottom(to: 0)
                    self.view.layoutIfNeeded()

                }
          }).disposed(by: lifeCycleDisposeBag)
        viewModel.eventResult.subscribe(onNext: { [weak self] event in
                
            self?.viewModelEventWorking(event: event)
        }).disposed(by: lifeCycleDisposeBag)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.viewDidAppear()
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
        
        bottomView.snp.remakeConstraints {
    
            $0.bottom.left.right.equalToSuperview()
            $0.height.equalTo(0)
        }
        
        viewModel.deleteIsEnable.subscribe(onNext: { [weak self] canDelete in
            
            guard let self = self else { return }
                
            self.deleteTokenButton.isEnabled = canDelete
            self.bottomView.isHidden = !canDelete
            if canDelete {
                    
                self.bottomView.snp.updateConstraints {
                        
                    $0.height.equalTo(ScaleWidth(at: 87))
                }
            } else {
                    
                self.bottomView.snp.updateConstraints {
                        
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
        photoVC.modalPresentationStyle = .fullScreen
        
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
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
}

extension UIDevice {
    
    var isIPhoneXUp: Bool {
        
        return UIScreen.main.bounds.height >= 812
    }
}
