
import UIKit
import RxSwift
import RxCocoa
import OneTimePassword
import Base32

protocol JoinManuallySectionItemsProtocol: BaseTableViewSectionItemsProtocol {
    
    var urlCellViewModel: JoinManuallyCellTextInItemsProtocol { get }
      
    var accountCellViewModel: JoinManuallyCellTextInItemsProtocol { get }
      
    var issuerCellViewModel: JoinManuallyCellTextInItemsProtocol { get }
      
    var keyTokenCellViewModel: JoinManuallyCellTextInItemsProtocol { get }
      
    var baseTimeCellViewModel: JoinManuallyCellSwitchItemsProtocol { get }
}

protocol JoinManuallyCellTextInItemsProtocol: BaseTableViewCellViewModelProtocol {
    
    var title: String { get }
    var textfieldPlaceHolder: String { get }
    var inputString: BehaviorSubject<String> { get }
    var isNameOrIssuerTextField: Bool { get }
}

class JoinManuallyCellTextInItems: JoinManuallyCellTextInItemsProtocol {
    
    let isNameOrIssuerTextField: Bool
    
    let title: String
    
    let textfieldPlaceHolder: String
    
    let inputString: BehaviorSubject<String> = .init(value: "")
    
    let baseCellItem: BaseTableViewCellViewModelItemProtocol
    
    var cellFactoryType: TableViewCellFactoryType { .joinManuallyTextIn(viewModel: self) }
    
    internal init(title: String,
                  textfieldPlaceHolder: String,
                  isNameOrIssuerTextField: Bool,
                  baseCellItem: BaseTableViewCellViewModelItemProtocol =
        BaseTableViewCellViewModelItem(cellSelectionStyle: .init(value: .none),
                                       cellHeight: UITableView.automaticDimension,
                                       cellBackgroundColor: .init(value: .clear),
                                       cellContentViewBGColor: .init(value: .clear))) {
        
        self.title = title
        self.textfieldPlaceHolder = textfieldPlaceHolder
        self.baseCellItem = baseCellItem
        self.isNameOrIssuerTextField = isNameOrIssuerTextField
    }
    
}

protocol JoinManuallyCellSwitchItemsProtocol: BaseTableViewCellViewModelProtocol {
    
    var title: String { get }
    var switcher: BehaviorSubject<Bool> { get }
}

class JoinManuallyCellSwitchItems: JoinManuallyCellSwitchItemsProtocol {
    
        
    let switcher: BehaviorSubject<Bool> = .init(value: true)
    
    let title: String
    
    let baseCellItem: BaseTableViewCellViewModelItemProtocol
    
    var cellFactoryType: TableViewCellFactoryType { .joinManuallySwither(viewModel: self) }

    internal init(title: String,
                  baseCellItem: BaseTableViewCellViewModelItemProtocol = BaseTableViewCellViewModelItem(cellSelectionStyle: .init(value: .none),
                                                                                                        cellHeight: 100,
                                                                                                        cellBackgroundColor: .init(value: .clear),
                                                                                                        cellContentViewBGColor: .init(value: .clear))) {
        
        self.title = title
        self.baseCellItem = baseCellItem
    }
}



class JoinManuallySectionItems: JoinManuallySectionItemsProtocol {
    
    let sectionHeaderViewModel: BaseTableViewSectionHeaderFooterViewModelProtocol? = nil
    
    let sectionFooterViewModel: BaseTableViewSectionHeaderFooterViewModelProtocol? = nil
    
    var numberOfRow: Int { cellViewModels.count }
    
    subscript(index: Int) -> BaseTableViewCellViewModelProtocol {
        
        return cellViewModels[index]
    }
    
    private var cellViewModels: [BaseTableViewCellViewModelProtocol] {
        
        return [urlCellViewModel, accountCellViewModel, issuerCellViewModel, keyTokenCellViewModel, baseTimeCellViewModel]
    }
    
    let urlCellViewModel: JoinManuallyCellTextInItemsProtocol
    
    let accountCellViewModel: JoinManuallyCellTextInItemsProtocol
    
    let issuerCellViewModel: JoinManuallyCellTextInItemsProtocol
    
    let keyTokenCellViewModel: JoinManuallyCellTextInItemsProtocol
    
    let baseTimeCellViewModel: JoinManuallyCellSwitchItemsProtocol
    
    init(urlCellViewModel: JoinManuallyCellTextInItemsProtocol = JoinManuallyCellTextInItems(title: "验证码",
                                                                                             textfieldPlaceHolder: "otpauth://", isNameOrIssuerTextField: false),
         accountCellViewModel: JoinManuallyCellTextInItemsProtocol = JoinManuallyCellTextInItems(title: "账号",
                                                                                                 textfieldPlaceHolder: "hello@example.com", isNameOrIssuerTextField: true),
         issuerCellViewModel: JoinManuallyCellTextInItemsProtocol = JoinManuallyCellTextInItems(title: "issuer",
                                                                                                textfieldPlaceHolder: "small-chat-test", isNameOrIssuerTextField: true),
         keyTokenCellViewModel: JoinManuallyCellTextInItemsProtocol = JoinManuallyCellTextInItems(title: "密钥",
                                                                                                  textfieldPlaceHolder: "fwjf btrf", isNameOrIssuerTextField: false),
         baseTimeCellViewModel: JoinManuallyCellSwitchItemsProtocol = JoinManuallyCellSwitchItems(title: "基于时间")) {
         
        self.urlCellViewModel = urlCellViewModel
        self.accountCellViewModel = accountCellViewModel
        self.issuerCellViewModel = issuerCellViewModel
        self.keyTokenCellViewModel = keyTokenCellViewModel
        self.baseTimeCellViewModel = baseTimeCellViewModel
    }
}

protocol JoinManuallyVCViewModelProtocol: BaseTableViewVCViewModelProtocol {
    
    var buttonEnable: Observable<Bool> { get }

    func addTOTP() -> Observable<JoinManuallyVCViewModel.Event>
}

class JoinManuallyVCViewModel: BaseVCViewModel, JoinManuallyVCViewModelProtocol {
    
    enum Event {
        
        case success
        case alertAction(title: String, message: String, completion: () -> Void)
        case secretError
    }
    
    let buttonEnable: Observable<Bool>
    
    init(navigationItemViewModel: BaseNavigaitonItemProtocol = BaseNavigaitonItem(title: .init(value: "手动输入")),
         joinManuallySectionItems: JoinManuallySectionItemsProtocol = JoinManuallySectionItems(),
         tokenStore: TokenStoreProtocol = KeychainTokenStore.shared,
         pastedString: String? = nil) {
        
        self.joinManuallySectionItems = joinManuallySectionItems
        self.tokenStore = tokenStore
        
        self.buttonEnable = Observable.combineLatest(joinManuallySectionItems.accountCellViewModel.inputString,
                                                     joinManuallySectionItems.keyTokenCellViewModel.inputString)
                                                    .map({$0.0.count > 0 && $0.1.count > 0})
        
        super.init(navigationItem: navigationItemViewModel, backgroundColor: .manuallyTOTPBackgroundColor)
        
        if let wantPastedString = pastedString {
            
            joinManuallySectionItems.urlCellViewModel.inputString.onNext(wantPastedString)
        }
        
        let tokenObserver = joinManuallySectionItems.urlCellViewModel.inputString
                            .compactMap({ Token(customURL: URL(string: $0) ?? URL(fileURLWithPath: "")) })
        
        tokenObserver.map({$0.name})
            .bind(to: joinManuallySectionItems.accountCellViewModel.inputString)
            .disposed(by: disposedBag)
        
        tokenObserver.map({$0.issuer})
            .bind(to: joinManuallySectionItems.issuerCellViewModel.inputString)
            .disposed(by: disposedBag)
        
        
        joinManuallySectionItems.urlCellViewModel.inputString
            .compactMap({ try? $0.mustAuth.parsingSetURL().secretString })
            .bind(to: joinManuallySectionItems.keyTokenCellViewModel.inputString)
            .disposed(by: disposedBag)
        
        tokenObserver.map({
            
                if case .timer = $0.generator.factor {
                    
                    return true
                } else {
                    
                    return false
                }
            }).bind(to: joinManuallySectionItems.baseTimeCellViewModel.switcher)
            .disposed(by: disposedBag)
        
        tokenObserver.subscribe(onNext: { [weak self] token in
            
            self?.token = token
        }).disposed(by: disposedBag)
        
        intoAppPastedAction
            .bind(to: joinManuallySectionItems.urlCellViewModel.inputString)
            .disposed(by: disposedBag)
        
    }
  
    func addTOTP() -> Observable<Event> {
                
        return Observable<Event>.create { (anyObserver) -> Disposable in
            
            let disposed = Observable.combineLatest(self.joinManuallySectionItems.accountCellViewModel.inputString,
                                                    self.joinManuallySectionItems.issuerCellViewModel.inputString,
                                                    self.joinManuallySectionItems.keyTokenCellViewModel.inputString,
                                                    self.joinManuallySectionItems.baseTimeCellViewModel.switcher)
            .subscribe(onNext: { [weak self] account, issuer, key, baseTime in
                   
                guard let self = self else {
                    
                    return
                }
                
                guard key.count > 1, key.count < 201, key.mustAuth.regularExpression.validSecret() else {
                    
                    anyObserver.onNext(.secretError)
                    anyObserver.onCompleted()
                    return
                }
                
                guard let secret = MF_Base32Codec.data(fromBase32String: key) else {
                    anyObserver.onError(SerializationError.urlGenerationFailure)
                    return
                }
                
                guard !key.trimmingCharacters(in: .whitespaces).isEmpty else {
                    
                    anyObserver.onError(SerializationError.urlGenerationFailure)
                    return
                }
                
                let algorithm: Generator.Algorithm
                
                let digits: Int
                
                let factor: Generator.Factor
                
                if let token = self.token {
                                           
                    let tokenFactor = token.generator.factor
                     
                    algorithm = token.generator.algorithm
                     
                    digits = token.generator.digits
                                         
                     if baseTime {
                         
                         if case .counter = tokenFactor {
                             
                             factor = .timer(period: 30)
                         } else {
                             
                             factor = tokenFactor
                         }
                     } else {
                         
                         if case .counter = tokenFactor {
                             
                             factor = tokenFactor
                         } else {
                             
                             factor = .counter(0)
                         }
                     }
                } else {
                    
                    if baseTime {
                                         
                        factor = .timer(period: 30)
                    } else {
                                    
                        factor = .counter(0)
                    }
                    
                    algorithm = .sha1
                    digits = 6
                }
                
                guard let generator = Generator(factor: factor, secret: secret, algorithm: algorithm, digits: digits) else {
                    return }
                                
                guard !account.trimmingCharacters(in: .whitespaces).isEmpty else {
                    
                    anyObserver.onError(SerializationError.urlGenerationFailure)
                    return
                }
                
                let addToken = Token(name: account, issuer: issuer, generator: generator)
                
                self.tokenStore.addToken(addToken, groupNames: []) { (event) in
                    
                    switch event {
                                           
                        case .addSuccess:
                           
                            anyObserver.onNext(.success)
                            anyObserver.onCompleted()
                        case .haveTheSame(let title, let message, let completion):
                           
                            anyObserver.onNext(.alertAction(title: title, message: message, completion: completion))
                        case .addError(let error):
                           
                            anyObserver.onError(error)
                    }
                }
            })
        
            return Disposables.create { disposed.dispose() }
        }
        
    }
    
    var cellViewModels: [BaseTableViewSectionItemsProtocol] {
        
        return [joinManuallySectionItems]
    }
    
    var tableViewStyle: UITableView.Style { .grouped }
        
    private let joinManuallySectionItems: JoinManuallySectionItemsProtocol
    
    private let tokenStore: TokenStoreProtocol
    
    private var token: Token?
    
}

class JoinManuallyTOTPTypeViewController<ViewModel: JoinManuallyVCViewModelProtocol>: BaseTableViewController<ViewModel> {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.bounces = false
        
        let navigationBarButton = UIBarButtonItem(image: .noSmsDone, style: .plain, target: nil, action: nil)

        navigationItem.rightBarButtonItem = navigationBarButton
        
        viewModel.buttonEnable
            .bind(to: navigationBarButton.rx.isEnabled)
            .disposed(by: disposedBag)
        
        
        navigationBarButton.rx.tap.subscribe(onNext: { [weak self] _ in
            
            guard let self = self else { return }
            
            self.viewModel.addTOTP().subscribe(onNext: { [weak self] event in
                
                switch event {
                    
                case .success:
                    
                    self?.navigationController?.popViewController(animated: true)
                    
                case .alertAction(title: let title, message: let message, completion: let completion):
                    
                    self?.showAlert(title: title, message: message, confirmTitle: "确认", cancelTitle: "取消", confirmAction: completion, cancelAction: nil)
                case .secretError:
                    
                    NoSMSHUD.showToast(title: "密钥无效")
                }
            }, onError:  { _ in
                
                NoSMSHUD.showToast(title: "创建失败")

            }).disposed(by: self.disposedBag)
        }).disposed(by: disposedBag)
        
        NotificationCenter.default.rx
            .notification(UIWindow.keyboardWillShowNotification)
            .compactMap({$0.userInfo})
            .compactMap({$0[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect})
            .map({$0.height})
            .subscribe(onNext: { [weak self] height in
                 guard let self = self else { return }
                 if UIApplication.shared.applicationState == .active  {
                     UIView.animate(withDuration: 0.1) {
                                       
                         self.tableView.changeBottom(to: -height)
                         self.view.layoutIfNeeded()
                     }
                 }
            }).disposed(by: disposedBag)
        
         NotificationCenter.default.rx
             .notification(UIWindow.keyboardWillHideNotification)
             .subscribe(onNext: { [weak self] _ in
                 guard let self = self else { return }
               
                 UIView.animate(withDuration: 0.1) {
                   
                     self.tableView.changeBottom(to: 0)
                     self.view.layoutIfNeeded()

                 }
           }).disposed(by: disposedBag)
    }
}


extension Data {
    
    func getMustAuthSecret() -> String {
        
        return MF_Base32Codec.base32String(from: self)
    }
}
