
import UIKit
import RxSwift
import RxCocoa
import DynamicBlurView




class ShareOTPViewController<VCViewModel: TokenListVCViewModelProtocol>: BaseTableViewController<VCViewModel>, UITextFieldDelegate, UIPopoverPresentationControllerDelegate {
    private var groupDisposedBag: DisposeBag = .init()
    private var lifeCycleDisposeBag: DisposeBag = .init()
    let tokenListMenuVC:TokenListMenuViewController = .init(viewModel: TokenListMenuVCViewModel())
    
    private var groupVCs: [TokenListGroupViewController] = []
  
    
    private var isFirstOpen:Bool = true
    private lazy var addTokenBarButton: UIBarButtonItem = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.setImage(.noSmsAdd, for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 40, height: 25)
        button.rx.tap.subscribe(onNext: { [weak self] _ in
            
            guard let self = self else { return }
            self.tokenListMenuVC.preferredContentSize = CGSize(width: ScaleWidth(at: 144),height: ScaleWidth(at: 144))
            self.tokenListMenuVC.modalPresentationStyle = .popover
            var popover = self.tokenListMenuVC.popoverPresentationController!
            popover.delegate = self
            popover.popoverBackgroundViewClass = MyPopoverBackgroundView.self
            popover.barButtonItem = self.addTokenBarButton
            self.present(self.tokenListMenuVC, animated: true)
            if self.searchTextField.isFirstResponder {
                
                self.searchTextField.resignFirstResponder()
            }
            
        }).disposed(by: disposedBag)
        
        let barBtn = UIBarButtonItem(customView: button)
        return barBtn
    }()
    
    private lazy var exportOTPButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.setTitle("导出验证码", for: .normal)
        button.titleLabel?.textColor = .white
        button.frame = CGRect(x: 0, y: 0, width: 345, height: 42)
        if otpShareSelectedAccount.isEmpty {
            button.isEnabled = false
            button.backgroundColor = .exportOTPDisableTextColor
        } else {
            button.isEnabled = true
            button.backgroundColor = .exportOTPEnableTextColor
        }
        button.addCornerRadius(at: 10)
        button.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            let shareRecordManager = ShareRecordStoreManager()
            shareRecordManager.addNewRecord(description: "导出：\(self.otpShareSelectedAccount.count)个验证码")
            let newViewController = QRcodeOTPShareViewController()
            newViewController.otpShareSelectedAccount = self.otpShareSelectedAccount
            newViewController.view.backgroundColor = .optShareBackgroundColor
            self.navigationController?.pushViewController(newViewController, animated: true)
        }).disposed(by: disposedBag)
        return button
    }()
    private lazy var selectAllButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
               button.frame = CGRect(x: 0, y: 0, width: 60, height: 25)
               button.setTitle("取消全选", for: .normal)
               button.titleLabel?.textAlignment = .right
               button.titleLabel?.font = UIFont(name: TFontName.PingFangFontMedium.rawValue , size: 15)
               button.rx.tap
                   .subscribe(onNext: { [weak self] _ in
                       guard let self = self else { return }
                       if button.titleLabel?.text == "全选" {
                           NotificationCenter.default.post(name: Notification.Name("ChoseAllNotificationIdentifier"), object: nil, userInfo: ["selectAll": true])
                           button.setTitle("取消全选", for: .normal)
                           self.exportOTPButton.isEnabled = true
                           self.exportOTPButton.backgroundColor = .exportOTPEnableTextColor
                           self.customSegmentView.selectIndex(at: 0)
                           let tokenStore: TokenStoreProtocol = KeychainTokenStore.shared
                           self.otpShareSelectedAccount.removeAll()
                           for token in tokenStore.tokenList {
                               self.otpShareSelectedAccount.append("[\(token.token.issuer)] \(token.token.name)")
                           }
                       } else {
                           NotificationCenter.default.post(name: Notification.Name("ChoseAllNotificationIdentifier"), object: nil, userInfo: ["selectAll": false])
                           button.setTitle("全选", for: .normal)
                           self.exportOTPButton.isEnabled = false
                           self.exportOTPButton.backgroundColor = .exportOTPDisableTextColor
                           self.otpShareSelectedAccount.removeAll()
                       }
                       

                   }).disposed(by: disposedBag)
        return button
    }()
    
    
    private lazy var selectAllBarButton: UIBarButtonItem = {
        let barBtn = UIBarButtonItem(customView: selectAllButton)
        return barBtn
    }()
    
    private let inEditTableViewBarButton: UIBarButtonItem = .init(image: .noSmsDone, style: .plain, target: nil, action: nil)
    
    
    private let updateRedView: UIView = {
        
        let view = UIView()
        view.frame = .init(x: 25, y: 0, width: 8, height: 8)
        view.setBackgroundColor(.mustAuthRedColor)
            .addCornerRadius(at: 4)
        view.isHidden = true
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
        
        let textField = CustomTextField(frame: .zero)
        textField.textColor = .otpShareSearchTextColor
        textField.backgroundColor = .tokenListSearchTextFieldBackgroundColor
        textField.placeholder = "搜索"
        textField.font = .pingFangMediumFont(size: 15)
        textField.addCornerRadius(at: ScaleWidth(at: 6))
        
        textField.addCustomLeftView(image: .noSmsSearch, textViewMode: .always)
        textField.addCustomClearButton()
        textField.clearButton?.rx.tap.subscribe(onNext: { [weak self] in
            
            self?.cleanTextField()
        }).disposed(by: self.disposedBag)
        textField.returnKeyType = .search
        
        textField.delegate = self
        return textField
    }()
    
    private let resetSearchButton: UIButton = {
        
        let button = UIButton()
        button.setTitle("取消", for: .normal)
        button.setTitleColor( .tokenListResetSearchButton, for: .normal)
        button.titleLabel?.font = .pingFangMediumFont(size: 15)
        button.isHidden = true
        return button
    }()
    
    private let scrollView: UIScrollView = .init()
    
    private let editControllView: EditControllView = .init(frame: .zero)
    
    override func viewDidLoad() {
        super.viewDidLoad()
      
        isShareOTP = true
        self.navigationItem.title = "选择验证码"
        navigationController?.navigationBar.layer.shadowColor = UIColor.black.withAlphaComponent(0.12).cgColor
        navigationController?.navigationBar.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        navigationController?.navigationBar.layer.shadowRadius = 4.0
        navigationController?.navigationBar.layer.shadowOpacity = 1.0
        navigationController?.navigationBar.layer.masksToBounds = false
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .any, barMetrics: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        view.addSubview(searchTextField)
        view.addSubview(customSegmentView)
        view.addSubview(resetSearchButton)
        view.addSubview(scrollView)
        view.addSubview(homePageView)
        self.view.addSubview(exportOTPButton)
       
        NotificationCenter.default.addObserver(self, selector: #selector(self.receivedOTPNotification(notification:)), name: Notification.Name("OTPNotificationIdentifier"), object: nil)
        //navigationController?.view.addSubview(choseHowToAddTokenView)
        //navigationController?.view.addSubview(menuView)
        //navigationController?.view.addSubview(editControllView)
        tableView.showsVerticalScrollIndicator = false
        
        //        editControllView.snp.makeConstraints {
        //            //$0.edges.equalToSuperview()
        //        }
        
        editControllView.isHidden = true
        
        editControllView.eventPublish.subscribe(onNext: { [weak self] event in
            guard let self = self else { return }
            
            self.editControllView.isHidden = true
            
            switch event {
                
            case .code:
                
                if self.searchTextField.isFirstResponder {
                    
                    self.searchTextField.resignFirstResponder()
                }
                SwipeManager.shared.swipeOff()
                self.tableView.setEditing(true, animated: true)
                self.customSegmentView.selectIndex(at: 0)
                self.customSegmentView.snp.updateConstraints {
                    $0.height.equalTo(0)
                }
                self.scrollView.setContentOffset(.init(x: 0, y: 0), animated: false)
                self.scrollView.isScrollEnabled = false
                //                self.groupVCs.forEach({$0.tableView.setEditing(true, animated: true)})
                //                self.navigationItem.leftBarButtonItem?.isEnabled = false
                self.navigationItem.rightBarButtonItems = [self.inEditTableViewBarButton]
            case .group:
                
                self.navigationController?.pushViewController(.groupViewControllver, animated: true)
            }
        }).disposed(by: disposedBag)
        
        searchTextField.snp.makeConstraints {
            
            $0.top.equalToSuperview().offset(ScaleWidth(at: 8))
            $0.left.equalToSuperview().offset(ScaleWidth(at: 12))
            $0.right.equalTo(ScaleWidth(at: -12))
            $0.height.equalTo(ScaleWidth(at: 40))
        }
        
        customSegmentView.snp.makeConstraints {
            
            $0.top.equalTo(searchTextField.snp.bottom).offset(ScaleWidth(at: 8))
            $0.left.right.equalToSuperview()
            $0.height.equalTo(ScaleWidth(at: 0))
        }
        
        resetSearchButton.snp.makeConstraints {
            
            $0.top.bottom.equalTo(searchTextField)
            $0.right.equalToSuperview().offset(ScaleWidth(at: -12))
        }
        
        
        view.addSubview(bottomView)
        
        bottomView.addSubview(deleteTokenButton)
        bottomViewSetup()
        
        exportOTPButton.snp.makeConstraints {
            $0.bottom.equalToSuperview().offset(ScaleWidth(at: -48))
            $0.left.equalToSuperview().offset(ScaleWidth(at: 15))
            $0.right.equalToSuperview().offset(ScaleWidth(at: -15))
            $0.height.equalTo(ScaleWidth(at: 42))
            $0.centerX.equalToSuperview()
        }
        
        homePageView.snp.makeConstraints {
            
            $0.top.equalTo(view.snp.topMargin)
            $0.left.right.bottomMargin.equalToSuperview()
        }
        
        //        choseHowToAddTokenView.snp.makeConstraints {
        //
        //            $0.edges.equalToSuperview()
        //        }
        
        //        menuView.snp.makeConstraints {
        //
        //            $0.edges.equalToSuperview()
        //        }
        
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
        
        //navigationItem.leftBarButtonItem = leftBarButton
        
        inEditTableViewBarButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                
                self.navigationItem.leftBarButtonItem?.isEnabled = true
                if self.searchTextField.isFirstResponder {
                    
                    self.searchTextField.resignFirstResponder()
                }
                self.tableView.endEditing(true)
                self.tableView.setEditing(false, animated: true)
                self.scrollView.isScrollEnabled = true
                if !self.groupVCs.isEmpty {
                    
                    self.customSegmentView.snp.updateConstraints {
                        
                        $0.height.equalTo(ScaleWidth(at: 41))
                    }
                }
                //                self.groupVCs.forEach({$0.tableView.setEditing(false, animated: true)})
                self.viewModel.tableViewEndEdit()
                self.wantToShowHomePageOrNot()
                
            }).disposed(by: disposedBag)
        
        navigationItem.rightBarButtonItems = [selectAllBarButton]
        
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
            
            SwipeManager.shared.swipeOff()
            if (self.searchTextField.text?.isEmpty ?? true){
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.showSearchTextAction(tableView: self.tableView)
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
        
        scrollView.snp.makeConstraints {
            
            $0.top.equalTo(customSegmentView.snp.bottom)
            $0.left.right.equalToSuperview()
            $0.bottom.equalTo(bottomView.snp.top).offset(-100)
        }
        
        tableView.removeFromSuperview()
        scrollView.addSubview(tableView)
        scrollView.backgroundColor = .tokenListTableViewBackgroundColor
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        
        scrollView.panGestureRecognizer.rx.event.subscribe(onNext: { [weak self] gest in
            
            guard let self = self else { return }
            if gest.state == .ended {
                
                let lastPage = self.customSegmentView.selectIndex
                
                let width = self.scrollView.bounds.width
                let allContent = CGFloat(lastPage) * width
                
                let contentWidth = self.scrollView.contentOffset.x
                
                if contentWidth > allContent {
                    
                    if self.groupVCs.count == lastPage {
                        
                        
                    } else {
                        
                        self.customSegmentView.selectIndex(at: lastPage + 1)
                    }
                } else {
                    
                    if lastPage == 0 {
                        
                        
                    } else {
                        
                        self.customSegmentView.selectIndex(at: lastPage - 1)
                    }
                }
            }
        }).disposed(by: disposedBag)
        
        viewModel.groupViewModels.subscribe(onNext: { [weak self] tableViewModels in
            
            guard let self = self else { return }
            
            for vc in self.groupVCs {
                
                vc.view.removeFromSuperview()
                vc.removeFromParent()
            }
            
            self.groupVCs = []
            self.groupDisposedBag = .init()
            
            for tableViewModel in tableViewModels {
                let viewController = TokenListGroupViewController(viewModel: tableViewModel)
                viewController.shareOTP = true
                self.groupVCs.append(viewController)
            }
            
            for vc in self.groupVCs {
                
                self.addChild(vc)
                self.scrollView.addSubview(vc.view)
                vc.tableView.backgroundColor = .tokenListTableViewBackgroundColor
                vc.tableView.rx.didScroll.subscribe(onNext: { [weak vc, weak self] in
                    guard let tableView = vc?.tableView else { return }
                    guard let self = self else { return }
                    
                    if (self.searchTextField.text?.isEmpty ?? true) {
                        
                        self.showSearchTextAction(tableView: tableView)
                    }
                }).disposed(by: self.groupDisposedBag)
                
                vc.tableView.rx.didScrollToTop.subscribe(onNext: { [weak self] in
                    guard let self = self else { return }
                    
                    if (self.searchTextField.text?.isEmpty ?? true){
                        
                        self.showSearchTextAnimation()
                    }
                }).disposed(by: self.groupDisposedBag)
            }
            
            let scrollSubView = self.scrollView.subviews
            
            for index in scrollSubView.indices {
                
                scrollSubView[index].snp.remakeConstraints {
                    
                    $0.top.bottom.height.width.equalToSuperview()
                    
                    if index == 0 {
                        
                        $0.left.equalToSuperview()
                    } else {
                        
                        $0.left.equalTo(scrollSubView[index - 1].snp.right)
                    }
                    
                    if index == scrollSubView.count - 1 {
                        
                        $0.right.equalToSuperview()
                    }
                }
            }
            self.customSegmentView.selectIndex(at: 0)
        }).disposed(by: disposedBag)
        
        viewModel.haveGroup
            .flatMapLatest(customSegmentViewSetup(hasGroup:))
            .subscribe()
            .disposed(by: disposedBag)
        customSegmentView.indexBehaiver.subscribe(onNext: { [weak self] index in
            
            guard let self = self else { return }
            
            let scrollViewWidth = self.scrollView.bounds.width
            self.scrollView.isScrollEnabled = false
            self.scrollView.setContentOffset(CGPoint(x: scrollViewWidth * CGFloat(index), y: 0), animated: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                
                //MARK: 因為編輯時會滾到到最前面會變成會滾於是編輯時不讓他可以滾
                if self.tableView.isEditing {
                    
                } else {
                    
                    self.scrollView.isScrollEnabled = true
                }
            }
            
        }).disposed(by: disposedBag)
        self.callVersionAPI()
    }
    
    @objc func receivedOTPNotification(notification: Notification) {
        let name = notification.userInfo?["name"] as? String ?? ""
        if otpShareSelectedAccount.contains(name) {
            if let index = otpShareSelectedAccount.firstIndex(of: name) {
                otpShareSelectedAccount.remove(at: index)
            }
        } else {
             otpShareSelectedAccount.append(name)
        }
        if otpShareSelectedAccount.isEmpty {
            exportOTPButton.isEnabled = false
            exportOTPButton.backgroundColor = .exportOTPDisableTextColor
        } else {
            exportOTPButton.isEnabled = true
            exportOTPButton.backgroundColor = .exportOTPEnableTextColor
        }
        if KeychainTokenStore.shared.tokenList.count != otpShareSelectedAccount.count {
            selectAllButton.setTitle("全选", for: .normal)
        } else {
            selectAllButton.setTitle("取消全选", for: .normal)
        }
    }

    
    private func showSearchTextAction(tableView: UITableView){
        
        if !self.searchTextField.isEditing && tableView.contentSize.height > tableView.frame.height {
            if tableView.panGestureRecognizer.translation(in: tableView).y < 0 || ( tableView.contentOffset.y > tableView.panGestureRecognizer.translation(in: tableView).y) {
                
                DispatchQueue.main.async {[weak self] in
                    guard let self = self else {return}
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
                    
                    self.customSegmentView.snp.updateConstraints {
                        $0.top.equalTo(self.searchTextField.snp.bottom).offset(ScaleWidth(at: 0))
                    }
                }
            }else {
                if tableView.contentOffset.y < 0 {
                    showSearchTextAnimation()
                }
            }
        }else {
            if tableView.contentOffset.y < 0 {
                showSearchTextAnimation()
            }
        }
    }
    private func showSearchTextAnimation(){
        
        DispatchQueue.main.async {[weak self] in
            guard let self = self else{return}
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
            self.customSegmentView.snp.updateConstraints {
                $0.top.equalTo(self.searchTextField.snp.bottom).offset(ScaleWidth(at: 8))
            }
        }
    }
    private func callVersionAPI(){
        
        Repository.sharedInstance.postVersion {[weak self] (result) in
            switch result {
            case .success(let items):
                DispatchQueue.main.async {
                    self?.menuView.reloadTableViewData()
                    self?.setupRedView()
                }
                
            case .failure(_):
                
                DispatchQueue.main.async {
                    
                    self?.setupRedView()
                }
            }
        }
    }
    private func viewModelEventWorking(event: TokenListViewModelEvent) {
        
        switch event {
        case .reloadData:
            
            tableView.reloadData()
            groupVCs.forEach({ $0.tableView.reloadData()})
            wantToShowHomePageOrNot()
        case .resetSearch:
            tableView.reloadData()
            wantToShowHomePageOrNot()
            resetSearch()
        case .scrollToIndex(let indexPath):
            
            customSegmentView.selectIndex(at: 0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {[weak self] in
                guard let self = self else { return }
                self.tableView.reloadData()
                self.wantToShowHomePageOrNot()
                self.resetSearch()
                self.tableView.scrollToRow(at: indexPath, at: .bottom, animated: false)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.showSearchTextAction(tableView: self.tableView)
                    if let view = self.tableView.cellForRow(at: indexPath) as? TokenListTableViewCell<TokenListTableViewCellViewModel> {
                        view.setBackCardAnimationColor()
                    }
                }
            }
            
        case .error(_):
            break
        case .empty:
            break
        case .addPin(let id):
            
            groupVCs.forEach({ $0.addPinRefresh(id: id)})
            
            let cells = tableView.visibleCells.compactMap({ $0 as? TokenListTableViewCell<TokenListTableViewCellViewModel>})
            var haveCellVisible = false
            
            for cell in cells {
                
                if cell.viewModel?.tokenID == id ,let indexPath = tableView.indexPath(for: cell) {
                    cell.viewModel?.setPin(isPin: true)
                    cell.resetPinStatus()
                    tableView.beginUpdates()
                    tableView.moveRow(at: indexPath, to: IndexPath(row: 0, section: 0))
                    tableView.endUpdates()
                    haveCellVisible = true
                    break
                }
            }
            
            if !haveCellVisible {
                
                tableView.reloadData()
            }
            
        case .removePin(let id):
            
            groupVCs.forEach({ $0.removePinRefresh(id: id)})
            // 超級硬來
            let cells = tableView.visibleCells.compactMap({ $0 as? TokenListTableViewCell<TokenListTableViewCellViewModel>})
            
            var haveCellVisible = false
            
            for cell in cells {
                
                if cell.viewModel?.tokenID == id ,let indexPath = tableView.indexPath(for: cell) {
                    cell.viewModel?.setPin(isPin: false)
                    cell.resetPinStatus()
                    tableView.beginUpdates()
                    tableView.moveRow(at: indexPath, to: IndexPath(row: 0, section: 1))
                    tableView.endUpdates()
                    haveCellVisible = true
                    break
                }
            }
            
            if !haveCellVisible {
                
                tableView.reloadData()
            }
        }
    }
    
    private func customSegmentViewSetup(hasGroup: Bool) -> Completable {
        
        return Completable.create { (handler) -> Disposable in
            
            let viewHeight: CGFloat
            
            if hasGroup {
                
                viewHeight = ScaleWidth(at: 41)
            } else {
                
                viewHeight = 0
            }
            
            self.customSegmentView.snp.updateConstraints {
                
                $0.height.equalTo(viewHeight)
            }
            handler(.completed)
            return Disposables.create {
                
            }
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
                scrollView.isScrollEnabled = true
                groupVCs.forEach({$0.tableView.setEditing(false, animated: true)})
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
                
                //                navigationItem.rightBarButtonItems = [beforeEditTableViewBarButton, addTokenBarButton]
                homePageView.isHidden = true
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.title = "选择验证码"
        wantToShowHomePageOrNot()
        
        viewModel.intoAppPastedAction.subscribe(onNext: { [weak self] pastedString in
            
            self?.showPastedStringAlert(pastedString: pastedString)
        }).disposed(by: lifeCycleDisposeBag)
        
        NotificationCenter.default.rx.notification(UIApplication.willResignActiveNotification).subscribe({[weak self] _ in
            guard let self = self else { return }
            //            if self.tokenListMenuVC.isViewLoaded {
            self.tokenListMenuVC.dismiss(animated: false, completion: nil)
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
        
        setupRedView()
    }
    
    private func setupRedView() {
        
        let isGoInSettingPageBefore = AuthIDStatusManager.isGoInSettingPageBefore
        let isUpdate = Repository.sharedInstance.version?.isNeedUpdate ?? false
        
        let redViewIsHide: Bool
        
        if isUpdate {
            
            redViewIsHide = false
        } else if !isGoInSettingPageBefore {
            
            redViewIsHide = false
        } else {
            
            redViewIsHide = true
        }
        
        updateRedView.isHidden = redViewIsHide
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.viewDidAppear()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
         self.navigationItem.title = ""
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
        
        let photoVC = BaseNavigationController(rootViewController: PhotoCheckViewController(viewModel: PhotoCheckVCViewModel()))
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
    
    private lazy var customSegmentView = CustomSegmentControl(viewModel: viewModel.customSegmentControlViewModel)
    
    
}










