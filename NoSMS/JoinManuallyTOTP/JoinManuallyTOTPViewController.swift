
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
}

class JoinManuallyCellTextInItems: JoinManuallyCellTextInItemsProtocol {
    
    let title: String
    
    let textfieldPlaceHolder: String
    
    let inputString: BehaviorSubject<String> = .init(value: "")
    
    let baseCellItem: BaseTableViewCellViewModelItemProtocol
    
    var cellFactoryType: TableViewCellFactoryType { .joinManuallyTextIn(viewModel: self) }
    
    internal init(title: String,
                  textfieldPlaceHolder: String,
                  baseCellItem: BaseTableViewCellViewModelItemProtocol =
        BaseTableViewCellViewModelItem(cellSelectionStyle: .init(value: .none),
                                       cellHeight: 100,
                                       cellBackgroundColor: .init(value: .clear),
                                       cellContentViewBGColor: .init(value: .clear))) {
        
        self.title = title
        self.textfieldPlaceHolder = textfieldPlaceHolder
        self.baseCellItem = baseCellItem
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
                                                                                             textfieldPlaceHolder: "otpauth://"),
         accountCellViewModel: JoinManuallyCellTextInItemsProtocol = JoinManuallyCellTextInItems(title: "账号",
                                                                                                 textfieldPlaceHolder: "hello@example.com"),
         issuerCellViewModel: JoinManuallyCellTextInItemsProtocol = JoinManuallyCellTextInItems(title: "issuer",
                                                                                                    textfieldPlaceHolder: "smaill-chat-text"),
         keyTokenCellViewModel: JoinManuallyCellTextInItemsProtocol = JoinManuallyCellTextInItems(title: "密钥",
                                                                                                  textfieldPlaceHolder: "fwjf btrf"),
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

    func addTOTP() -> Completable
}

class JoinManuallyVCViewModel: BaseVCViewModel, JoinManuallyVCViewModelProtocol {
    
    let buttonEnable: Observable<Bool>
    
    init(navigationItemViewModel: BaseNavigaitonItemProtocol = BaseNavigaitonItem(title: .init(value: "手动输入验证码")),
         joinManuallySectionItems: JoinManuallySectionItemsProtocol = JoinManuallySectionItems(),
         tokenStore: TokenStoreProtocol = KeychainTokenStore.shared,
         pastedString: String? = nil) {
        
        self.joinManuallySectionItems = joinManuallySectionItems
        self.tokenStore = tokenStore
        
        self.buttonEnable = Observable.combineLatest(joinManuallySectionItems.accountCellViewModel.inputString,
                                                     joinManuallySectionItems.issuerCellViewModel.inputString,
                                                     joinManuallySectionItems.keyTokenCellViewModel.inputString)
                                                    .map({$0.0.count > 0 && $0.1.count > 0 && $0.2.count > 0 })
        
        super.init(navigationItem: navigationItemViewModel, backgroundColor: .white)
        
        if let wantPastedString = pastedString {
            
            joinManuallySectionItems.urlCellViewModel.inputString.onNext(wantPastedString)
        }
        
        let tokenObserver = joinManuallySectionItems.urlCellViewModel.inputString
                            .compactMap({ Token(url: URL(string: $0) ?? URL(fileURLWithPath: "")) })
        
        tokenObserver.map({$0.name})
            .bind(to: joinManuallySectionItems.accountCellViewModel.inputString)
            .disposed(by: disposedBag)
        
        tokenObserver.map({$0.issuer})
            .bind(to: joinManuallySectionItems.issuerCellViewModel.inputString)
            .disposed(by: disposedBag)
        
        
        joinManuallySectionItems.urlCellViewModel.inputString
            .compactMap({ try? $0.totp.urlStringParsing().secretString })
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
  
    func addTOTP() -> Completable {
                
        return Completable.create { (completion) -> Disposable in
            
            let disposed = Observable.combineLatest(self.joinManuallySectionItems.accountCellViewModel.inputString,
                                                    self.joinManuallySectionItems.issuerCellViewModel.inputString,
                                                    self.joinManuallySectionItems.keyTokenCellViewModel.inputString,
                                                    self.joinManuallySectionItems.baseTimeCellViewModel.switcher)
            .subscribe(onNext: { [weak self] account, issuer, key, baseTime in
                   
                guard let self = self else { return }
                
                guard let secret = MF_Base32Codec.data(fromBase32String: key) else { return }
                
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
                
                let addToken = Token(name: account, issuer: issuer, generator: generator)
                
                do {
                    try self.tokenStore.addToken(addToken)
                    completion(.completed)
                } catch {
                    
                    completion(.error(error))
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
        
        
        navigationBarButton.rx.tap.subscribe { [weak self] _ in
            
            guard let self = self else { return }
            
            self.viewModel.addTOTP().subscribe(onCompleted: { [weak self] in
                self?.navigationController?.popViewController(animated: true)
            }).disposed(by: self.disposedBag)
        }.disposed(by: disposedBag)
    }
}
