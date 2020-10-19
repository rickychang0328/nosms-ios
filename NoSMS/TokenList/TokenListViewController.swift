
import UIKit
import RxSwift
import RxCocoa
import DynamicBlurView
import LocalAuthentication
import BiometricAuthentication

enum TokenListViewModelEvent {
    
    case reloadData
    case resetSearch
    case scrollToIndex(IndexPath)
    case error(Error)
    case empty
    //MARK: 偷時間
    case addPin(id: Data)
    case removePin(id: Data)
}

protocol TokenListVCViewModelProtocol: BaseTableViewVCViewModelProtocol {
    
    var eventResult: BehaviorSubject<TokenListViewModelEvent> { get }
    var deleteIsEnable: Observable<Bool> { get }
    var tokenIsEmpty: Bool { get }
    var customSegmentControlViewModel: CustomSegmentControlViewModelType { get }
    var groupViewModels: Observable<[TokenListInGroupVCViewModel]> { get }
    var haveGroup: Observable<Bool> { get }
    
    func deleteToken()
    func swapToken(beforeIndex: Int, afterIndex: Int)
    func tableViewEndEdit()
    func searchText(input: String)
    func viewDidAppear()
    func selectItem(indexPath: IndexPath) -> Observable<String>
}


class TokenListSupportPin {
    
    internal init(noPinTokenSection: TokenListSectionItemProtocol = TokenListSectionItem(),
                  pinTokenSection: TokenListSectionItemProtocol = TokenListSectionItem()) {
        
        self.noPinTokenSection = noPinTokenSection
        self.pinTokenSection = pinTokenSection
    }
    
    var allTokenViewModel: [TokenListTableViewCellViewModelProtocol] = []
    let noPinTokenSection: TokenListSectionItemProtocol
    let pinTokenSection: TokenListSectionItemProtocol
    
    private var searchString: String = .init()
    var sections: [TokenListSectionItemProtocol] {
        
        return [pinTokenSection, noPinTokenSection]
    }
    
    func setupTokens(tokens: [TokenListTableViewCellViewModelProtocol]) {
        
        //MARK: 一樣的數值只是改變位置就改順序而已
        if tokens.count == allTokenViewModel.count {
            
            let sortList = tokens.map({$0.tokenID})
            let result = sortList.compactMap({ uuid in
                return self.allTokenViewModel.first(where: { $0.tokenID == uuid})
            })
            
            allTokenViewModel = result
            
        } else {
            
            allTokenViewModel = tokens
        }
        
        reloadPin()
    }
    
    func reloadPin() {
        
        let pinList = KeychainTokenStore.shared.getPinList()
        let pinTokens = allTokenViewModel.filter({ pinList.contains($0.tokenID) })
        let noPinTokens = allTokenViewModel.filter({ !pinList.contains($0.tokenID) })
        let pinSortTokens = pinList.compactMap({ uuid in
            return pinTokens.first(where: { token in
                token.tokenID == uuid
            })})
        
        pinTokenSection.rowItems = pinSortTokens
        noPinTokenSection.rowItems = noPinTokens
        
        for item in noPinTokenSection.rowItems {
            
            item.setPin(isPin: false)
        }
        
        for item in pinTokenSection.rowItems {
            
            item.setPin(isPin: true)
        }
    }
    
    func setSearchString(input: String) {
        
        searchString = input
        pinTokenSection.setSearchString(input: input)
        noPinTokenSection.setSearchString(input: input)
    }
    
    func isSameString(input: String) -> Bool {
        
        return input == searchString
    }
    
    func getTokenID(at indexPath: IndexPath) -> Data {
        
        let tokenIndex = sections[indexPath.section].getRealIndex(afterSearchIndex: indexPath.row)
        let tokenViewModel = sections[indexPath.section].rowItems[tokenIndex]
        return tokenViewModel.tokenID
    }
    
    func getRealIndex(indexPath: IndexPath) -> Int {
        
        let tokenIndex = sections[indexPath.section].getRealIndex(afterSearchIndex: indexPath.row)
        let tokenViewModel = sections[indexPath.section].rowItems[tokenIndex]
        let result = allTokenViewModel.firstIndex(where: { $0.tokenID == tokenViewModel.tokenID})
        return result ?? 0
    }
    
    func getIndexPath(id: Data) -> IndexPath {
        
        let section: Int
        let row: Int
        
        for indexSec in sections.indices {
            
            for indexRow in sections[indexSec].rowItems.indices {
                
                if sections[indexSec].rowItems[indexRow].tokenID == id {
                    
                    section = indexSec
                    row = indexRow
                    
                    return IndexPath(row: row, section: section)
                }
            }
        }
        
        return IndexPath.init()
    }
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

extension String {
    
    func haveChineseWordAndOverSixWord() -> Bool {
        
        var haveChineseWord: Bool = false
        
        for subString in self {
            
            if subString.isChineseWord() {
                
                haveChineseWord = true
                break
            }
        }
        
        return haveChineseWord && (self.count > 6)
    }
}

extension Character {
    
    func isChineseWord() -> Bool {
        
        if ("\u{4E00}" <= self  && self <= "\u{9FA5}") {
            return true
        } else {
            
            return false
        }
    }
}

struct CustomSegmentControlViewModel: CustomSegmentControlViewModelType {
    
    let titles: Observable<[String]>
    
    init(titles: Observable<[String]>) {
        
        let resultTitles = titles.map({["全部"] + $0}).map({$0.map({ string -> String in
            
            let result: String
            if string.haveChineseWordAndOverSixWord() {
                
                var reString = ""
                
                for (index, char) in string.enumerated() {
                    if index >= 6 {
                        
                        break
                    }
                    reString.append(char)
                }
                
                reString = reString + "..."
                result = reString
            } else {
                
                result = string
            }
            
            return result
        })})
        
        self.titles = resultTitles
    }
}

class TokenListInGroupVCViewModel: BaseVCViewModel, BaseTableViewVCViewModelProtocol {
    
    var cellViewModels: [BaseTableViewSectionItemsProtocol] {
        
        return tokenListSupportPin.sections
    }
    
    var tableViewStyle: UITableView.Style { return .grouped }
    
    let tokenListSupportPin: TokenListSupportPin
    
    private let groupObject: GroupObject
    
    init(tokenListSupportPin: TokenListSupportPin,
         groupID: UUID) {
        
        self.tokenListSupportPin = tokenListSupportPin
        self.groupObject = KeychainTokenStore.shared.getGroup(uuid: groupID) ?? GroupObject()
        
        super.init(navigationItem: BaseNavigaitonItem(title: .init(value: "")), backgroundColor: .clear)
    }
    
    private var viewModels: [TokenListTableViewCellViewModelProtocol] = []
    
    func setCellViewModel(viewModels: [TokenListTableViewCellViewModelProtocol]) {
        
        let realViewModel = viewModels.filter({self.groupObject.tokens.contains($0.tokenID)})
        self.viewModels = viewModels
        tokenListSupportPin.setupTokens(tokens: realViewModel)
    }
    
    func setSearchText(input: String) {
        
        tokenListSupportPin.setSearchString(input: input)
    }
    
    func selectItem(indexPath: IndexPath) -> Observable<String> {
        
        let id = tokenListSupportPin.getTokenID(at: indexPath)
        
        let realIndex = viewModels.firstIndex(where: {$0.tokenID == id})!
        
        let observer: Observable<String> = .create { anyObserver -> Disposable in
            
            let disposed = KeychainTokenStore.shared.persistentTokensBehavior
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
    
}

class TokenListVCViewModel: BaseVCViewModel, TokenListVCViewModelProtocol {
    
    let haveGroup: Observable<Bool>
    
    var groupViewModels: Observable<[TokenListInGroupVCViewModel]> {
        
        return groupViewModelsBehavior.asObservable()
    }
    
    private let groupViewModelsBehavior: BehaviorSubject<[TokenListInGroupVCViewModel]> = .init(value: [])
    
    private var _groupViewModels: [TokenListInGroupVCViewModel] = [] {
        
        didSet {
            
            groupViewModelsBehavior.onNext(_groupViewModels)
        }
    }
    
    let customSegmentControlViewModel: CustomSegmentControlViewModelType
    
    var tokenIsEmpty: Bool {
        
        return tokenStore.tokenIsEmpty
    }
    
    let deleteIsEnable: Observable<Bool>
    let eventResult: BehaviorSubject<TokenListViewModelEvent> = .init(value: .reloadData)
    
    var tableViewStyle: UITableView.Style {
        
        return .grouped
    }
    
    var cellViewModels: [BaseTableViewSectionItemsProtocol] {
        
        return tokenListSupportPin.sections
    }
    
    private let tokenStore: TokenStoreProtocol
    
    private var isFirstOpen: Bool = true
    
    private let tokenListSupportPin: TokenListSupportPin
    
    init(navigationItemViewModel: BaseNavigaitonItemProtocol = BaseNavigaitonItem(title: .init(value: "MustAuth")),
         tokenStore: TokenStoreProtocol = KeychainTokenStore.shared,
         backgroundColor: UIColor = .tokenListBackgroundColor,
         tokenListSupportPin: TokenListSupportPin = TokenListSupportPin()) {
        
        self.tokenStore = tokenStore
        self.deleteIsEnable = tokenStore.haveSelectTokenToDelete
        self.tokenListSupportPin = tokenListSupportPin
        
        //TODO:
        let groupListTitleObserber = KeychainTokenStore.shared.groupListBehavior.map({ $0.map { $0.title } }).asObservable()
        self.customSegmentControlViewModel = CustomSegmentControlViewModel(titles: groupListTitleObserber)
        self.haveGroup = KeychainTokenStore.shared.groupListBehavior.map({!$0.isEmpty})
        super.init(navigationItem: navigationItemViewModel, backgroundColor: backgroundColor)
        
        KeychainTokenStore.shared.groupListBehavior.subscribe(onNext: { [weak self] groups in
            guard let self = self else { return }
            self._groupViewModels = groups.map({ TokenListInGroupVCViewModel(tokenListSupportPin: TokenListSupportPin(), groupID: $0.uuid)})
            
            for groupViewModel in self._groupViewModels {
                
                groupViewModel.setCellViewModel(viewModels: self.tokenListSupportPin.allTokenViewModel)
            }
        }).disposed(by: disposedBag)
        
        tokenStore.persistentTokensBehavior
            .map( {
                $0.map({
                    TableViewCellViewModelFactory.getCellViewModel(type: .tokenList($0))
                })
            }).subscribe(onNext: { [weak self] viewModels in
                guard let self = self else { return }
                
                //轉換變動不需要重新load, 不是新增 也不是刪除
                let count = self.tokenListSupportPin.allTokenViewModel.count
                self.tokenListSupportPin.setupTokens(tokens: viewModels)
                
                for groupViewModel in self._groupViewModels {
                    
                    groupViewModel.setCellViewModel(viewModels: viewModels)
                }
                
                if count == viewModels.count {
                    if self.isFirstOpen {
                        self.isFirstOpen = false
                        return
                    }
                    // 當變多的時候就增加成功 所以重置搜索狀態
                } else if count < viewModels.count {
                    
                    
                    self.eventResult.onNext(.resetSearch)
                    self.eventResult.onNext(.reloadData)
                    //初始化時就不觸發新增效果
                    
                    if self.isFirstOpen {
                        self.isFirstOpen = false
                        return
                    }
                    
                    let indexPath = self.tokenListSupportPin.getIndexPath(id: viewModels[viewModels.count - 1].tokenID)
                    
                    self.eventResult.onNext(.scrollToIndex(indexPath))
                    
                } else {
                    if self.isFirstOpen {
                        self.isFirstOpen = false
                    }
                    self.eventResult.onNext(.reloadData)
                    
                }
            })
            .disposed(by: disposedBag)
        
        tokenStore.pinEvent.subscribe(onNext: { [weak self] event in
            guard let self = self else { return }
            
            switch event {
                
            case .addPin(let id):
                
                self.tokenListSupportPin.reloadPin()
                self._groupViewModels.forEach({$0.tokenListSupportPin.reloadPin()})
                self.eventResult.onNext(.addPin(id: id))
                self.eventResult.onNext(.empty)
            case .remove(let id):
                
                //MARK: 壞了只能先硬幹一下
                self.eventResult.onNext(.removePin(id: id))
                self.eventResult.onNext(.empty)
            case .emtpy:
                break
            }
        }).disposed(by: disposedBag)
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
            let bef = tokenListSupportPin.getRealIndex(indexPath: IndexPath(row: beforeIndex, section: 1))
            let after = tokenListSupportPin.getRealIndex(indexPath: IndexPath(row: afterIndex, section: 1))
            try tokenStore.moveTokenFromIndex(bef, toIndex: after)
        } catch {
            
            eventResult.onNext(.error(error))
        }
    }
    
    func selectItem(indexPath: IndexPath) -> Observable<String> {
        
        let realIndex = tokenListSupportPin.getRealIndex(indexPath: indexPath)
        
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
        
        if tokenListSupportPin.isSameString(input: input) {
            
        } else {
            
            tokenListSupportPin.setSearchString(input: input)
            _groupViewModels.forEach({ $0.setSearchText(input: input) })
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

class TokenListGroupViewController: BaseTableViewControllerNoGeneric {
    
    private let viewModel: TokenListInGroupVCViewModel
    init(viewModel: TokenListInGroupVCViewModel) {
        
        self.viewModel = viewModel
        super.init(baseTableViewModel: viewModel)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.showsVerticalScrollIndicator = false
        tableView.rx.itemSelected
            .flatMapLatest(viewModel.selectItem(indexPath:))
            .subscribe(onNext: { [weak self] string in
                guard self != nil else { return }
                NoSMSHUD.showToast(title: string)
                
            }).disposed(by: disposedBag)
    }
    
    func addPinRefresh(id: Data) {
        
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
    }
    
    func removePinRefresh(id: Data) {
        
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
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
}

class TokenListViewController<VCViewModel: TokenListVCViewModelProtocol>: BaseTableViewController<VCViewModel>, UITextFieldDelegate, UIPopoverPresentationControllerDelegate {
    
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
                self.editControllView.isHidden = false
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
        textField.textColor = .tokenListSearchTextFieldTextColor
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
        
        navigationController?.view.addSubview(choseHowToAddTokenView)
        navigationController?.view.addSubview(menuView)
        navigationController?.view.addSubview(editControllView)
        tableView.showsVerticalScrollIndicator = false
        
        editControllView.shareOTPButton.rx.tap.subscribe(onNext: { [weak self] in
            guard let self = self else { return }
            let bioTitle = BioMetricAuthenticator.shared.isFaceIdDevice() ? "您的设备尚未开启面容ID识别" : "您的设备尚未开启指纹识别"
            if !UserDefaults.standard.bool(forKey: UserDefaults.Key.faceIDString.string) {
                self.showFaceIDAlert(title: "",
                                     message: bioTitle,
                                     confirmTitle: "设置",
                                     cancelTitle: "取消", confirmAction: {
                                        let newViewController = FaceIDSettingViewController()
                                        guard let navigationController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController else { return }
                                        navigationController.pushViewController(newViewController, animated: true)
                                        self.editControllView.isHidden = true
                                 
                }, cancelAction: {
                    
                })
                
                return
            }
            let newViewController = OTPShareAndReceiveViewController()
            newViewController.view.backgroundColor = .optShareBackgroundColor
//            guard let navigationController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController else { return }
            self.navigationController?.pushViewController(newViewController, animated: true)
            self.editControllView.isHidden = true
        }).disposed(by: disposedBag)
        
        editControllView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
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
                self.navigationItem.leftBarButtonItem?.isEnabled = false
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
            $0.bottom.equalTo(bottomView.snp.top)
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
                
                self.groupVCs.append(TokenListGroupViewController(viewModel: tableViewModel))
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
                
                navigationItem.rightBarButtonItems = [beforeEditTableViewBarButton, addTokenBarButton]
                homePageView.isHidden = true
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.title = "MustAuth"
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

extension UIDevice {
    
    var isIPhoneXUp: Bool {
        
        return UIScreen.main.bounds.height >= 812
    }
}


protocol CustomSegmentControlViewModelType {
    
    var titles: Observable<[String]> { get }
}

class CustomSegmentControl: UIView {
    
    private var titles: [String] = []
    
    private var gests: [UITapGestureRecognizer] = []
    
    private var labels: [UILabel] = []
    
    let indexBehaiver: BehaviorSubject<Int> = .init(value: 0)
    
    var selectIndex: Int = 0
    
    private let scrollView: UIScrollView = {
        
        let view = UIScrollView()
        view.showsHorizontalScrollIndicator = false
        return view
    }()
    
    private let underLine: UIView = {
        
        let view = UIView()
        view.setBackgroundColor(.customSegmentControlUnderLineColor)
        view.addCornerRadius(at: ScaleWidth(at: 2))
        return view
    }()
    
    private let secondUnderLine: UIView = {
        
        let view = UIView()
        view.setBackgroundColor(.customSegmentControlUnderLineColor)
        view.addCornerRadius(at: ScaleWidth(at: 2))
        return view
    }()
    
    private let disposedBag: DisposeBag = .init()
    
    private var gestDisposedBag: DisposeBag = .init()
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    convenience init(viewModel: CustomSegmentControlViewModelType) {
        
        self.init(frame: .zero)
        addSubview(scrollView)
        addSubview(underLine)
        clipsToBounds = true
        scrollView.snp.makeConstraints {
            
            $0.edges.equalToSuperview()
        }
        
        underLine.snp.makeConstraints {
            
            $0.height.equalTo(ScaleWidth(at: 4))
            $0.bottom.equalToSuperview().inset(ScaleWidth(at: 1))
            $0.width.left.equalToSuperview()
        }
        
        viewModel.titles.subscribe(onNext: { [weak self] titles in
            guard let self = self else { return }
            
            self.gestDisposedBag = .init()
            self.titles = titles
            self.gests = []
            self.labels = []
            
            for view in self.scrollView.subviews {
                
                view.removeFromSuperview()
            }
            
            for title in titles {
                
                let label = UILabel()
                label.text = title
                label.setFont(.pingFangMediumFont(size: 15))
                self.labels.append(label)
                self.scrollView.addSubview(label)
                let tapGest = UITapGestureRecognizer()
                label.addGestureRecognizer(tapGest)
                label.isUserInteractionEnabled = true
                self.gests.append(tapGest)
                
                
                tapGest.rx.event.subscribe(onNext: { [weak self] gest in
                    
                    guard let self = self else { return }
                    
                    guard let index = self.gests.firstIndex(of: gest) else {
                        
                        return
                    }
                    self.selectIndex(at: index)
                    
                }).disposed(by: self.gestDisposedBag)
                
            }
            
            let subViews = self.scrollView.subviews
            
            for index in subViews.indices {
                
                subViews[index].snp.makeConstraints {
                    
                    $0.centerY.height.equalToSuperview()
                    
                    if index == 0 {
                        
                        $0.left.equalToSuperview().offset(ScaleWidth(at: 16))
                    } else {
                        
                        $0.left.equalTo(subViews[index - 1].snp.right).offset(ScaleWidth(at: 40))
                    }
                    
                    if index == subViews.count - 1 {
                        
                        $0.right.equalToSuperview().inset(ScaleWidth(at: 16))
                    }
                }
                
            }
            self.resetUnderLine()
        }).disposed(by: disposedBag)
    }
    
    private func resetUnderLine() {
        
        if scrollView.subviews.isEmpty {
            
            return
        }
        
        underLine.snp.remakeConstraints {
            
            $0.left.width.equalTo(scrollView.subviews[0])
            $0.height.equalTo(ScaleWidth(at: 4))
            $0.bottom.equalToSuperview().inset(ScaleWidth(at: 1))
        }
    }
    
    
    func selectIndex(at index: Int) {
        
        let oldIndex = selectIndex
        
        for label in labels {
            
            label.setTextColor(.customSegmentControlDisnableTextColor)
        }
        
        labels[index].setTextColor(.customSegmentControlEnableTextColor)
        
        UIView.animate(withDuration: 0.2, animations: {
            
            self.underLine.snp.remakeConstraints {
                
                $0.left.width.equalTo(self.scrollView.subviews[index])
                $0.height.equalTo(ScaleWidth(at: 4))
                $0.bottom.equalToSuperview().inset(ScaleWidth(at: 1))
            }
            self.layoutIfNeeded()
        }, completion: { _ in
            
            let viewframeX = self.scrollView.subviews[index].frame.origin.x
            let contentOffsetX = self.scrollView.contentOffset.x
            let scrollViewWidth = self.scrollView.bounds.width
            let viewframeWidth = self.scrollView.subviews[index].bounds.width
            
            if viewframeX - contentOffsetX + viewframeWidth > scrollViewWidth {
                
                self.scrollView.setContentOffset(.init(x: viewframeX - (scrollViewWidth - viewframeWidth) + ScaleWidth(at: 16), y: 0), animated: true)
            } else if contentOffsetX + scrollViewWidth < viewframeX || contentOffsetX > viewframeX {
                
                let contentX = viewframeX == 0 ? 0 : viewframeX - ScaleWidth(at: 16)
                
                self.scrollView.setContentOffset(.init(x: contentX, y: 0), animated: true)
            }
        })
        
        selectIndex = index
        indexBehaiver.onNext(index)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class CustomTextField: UITextField {
    
    var clearButton: UIButton?
    
    var customObserverText: Observable<String?> {
        
        return customTextBehavior.asObservable()
    }
    
    private lazy var customTextBehavior: BehaviorSubject<String?> = {
        
        let behavior = BehaviorSubject<String?>(value: "")
        self.rx.text.bind(to: behavior).disposed(by: self.disposedBag)
        return behavior
    }()
    
    private let disposedBag: DisposeBag = .init()
    
    func addCustomLeftView(image: UIImage, textViewMode: UITextField.ViewMode) {
        
        let leftViewWidth = ScaleWidth(at: 18)
        let leftPan = ScaleWidth(at: 14)
        let leftPanAdd = ScaleWidth(at: 10)
        let leftView = UIView(frame: CGRect(x: 0, y: 0, width: leftViewWidth + leftPan + leftPanAdd, height: leftViewWidth))
        let leftImageView = UIImageView(frame: CGRect(x: leftPan, y: 0, width: leftViewWidth, height: leftViewWidth))
        leftImageView.image = image
        leftView.addSubview(leftImageView)
        self.leftView = leftView
        self.leftViewMode = textViewMode
    }
    
    func addCustomClearButton(rightPan: CGFloat = ScaleWidth(at: 8)) {
        
        let rightButtonWidth = ScaleWidth(at: 20)
        let rightPan = rightPan
        let leftViewWidth = ScaleWidth(at: 18)
        let rightView = UIView(frame: CGRect(x: 0, y: 0, width: rightButtonWidth + rightPan, height: leftViewWidth))
        let clearButton = UIButton(frame: CGRect(x: 0, y: 0, width: rightButtonWidth, height: rightButtonWidth))
        clearButton.setImage(.noSmsDelete, for: .normal)
        rightView.addSubview(clearButton)
        self.clearButton = clearButton
        self.rightView = rightView
        self.rightViewMode = .whileEditing
        rx.text
            .compactMap({$0})
            .map({!($0.count > 0)})
            .bind(to: rightView.rx.isHidden)
            .disposed(by: disposedBag)
        clearButton.rx.tap
            .subscribe(onNext: { [weak self, weak rightView] _ in
                rightView?.isHidden = true
                self?.text = ""
                self?.customTextBehavior.onNext("")
            }).disposed(by: disposedBag)
    }
}

class EditControllView: UIView {
    
    private let backImageView: UIImageView = {
        
        let view = UIImageView(image: .noSMSchoseEditControl)
        return view
    }()
    
    private let editCodeLabel: UILabel = {
        
        let label = UILabel()
        label.setFont(.pingFangMediumFont(size: 15))
            .setText("验证码管理")
            .setTextColor(.tokenListIssuerColor)
        return label
    }()
    
    private let editCodeImage: UIImageView = {
        
        let label = UIImageView(image: UIImage.noSMSchoseEditCode)
        return label
    }()
    
    private let editCodeButton: UIButton = {
        
        let button = UIButton()
        return button
    }()
    
    private let editGroupImage: UIImageView = {
        
        let label = UIImageView(image: UIImage.noSMSchoseEditGroup)
        return label
    }()
    
    private let shareOTPImage: UIImageView = {
        
        let label = UIImageView(image: UIImage(named: "NoSMS_share"))
        return label
    }()
    
    private let editGroupLabel: UILabel = {
        
        let label = UILabel()
        label.setFont(.pingFangMediumFont(size: 15))
            .setText("分组管理")
            .setTextColor(.tokenListIssuerColor)
        return label
    }()
    
    private let shareOTPLabel: UILabel = {
        
        let label = UILabel()
        label.setFont(.pingFangMediumFont(size: 15))
            .setText("验证码分享")
            .setTextColor(.tokenListIssuerColor)
        return label
    }()
    
    private let editGroupButton: UIButton = {
        
        let button = UIButton()
        return button
    }()
    
    let shareOTPButton: UIButton = {
        
        let button = UIButton()
        return button
    }()
    
    enum Event {
        
        case group
        case code
    }
    
    private let disposedBag: DisposeBag = .init()
    
    let eventPublish: PublishSubject<Event> = .init()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(backImageView)
        backImageView.addSubview(editCodeImage)
        backImageView.addSubview(editCodeLabel)
        backImageView.addSubview(editGroupImage)
        backImageView.addSubview(shareOTPImage)
        backImageView.addSubview(editGroupLabel)
        backImageView.addSubview(shareOTPLabel)
        addSubview(editCodeButton)
        addSubview(editGroupButton)
        addSubview(shareOTPButton)
        
        let underLine = UIView()
        let secondUnderLine = UIView()
        underLine.setBackgroundColor(.alertStreetUnderLineColor)
        secondUnderLine.setBackgroundColor(.alertStreetUnderLineColor)
        backImageView.addSubview(underLine)
        backImageView.addSubview(secondUnderLine)
        
        //適應各種奇怪的尺寸 layout
        let withWidth: CGFloat
        
        if UIScreen.main.bounds.width < 375 {
            //比對後給的值並不是絕對
            withWidth = 355
        } else {
            
            withWidth = 414
        }
        
        
        let topY: CGFloat
        if #available(iOS 11, *) {
            
            topY = 27
        } else {
            
            topY = 46
        }
        
        backImageView.snp.makeConstraints {
            $0.right.equalTo(0)
            $0.topMargin.equalTo(topY - 10)
            $0.width.equalTo(ScaleWidth(at: 161, with: withWidth))
            $0.height.equalTo(ScaleWidth(at: 175 + 15))
        }
        
        editCodeLabel.snp.makeConstraints {
            
            $0.centerY.equalTo(editCodeImage)
            $0.left.equalTo(ScaleWidth(at: 58, with: withWidth))
        }
        
        editCodeImage.snp.makeConstraints {
            
            $0.size.equalTo(ScaleWidth(at: 20, with: withWidth))
            $0.top.equalTo(ScaleWidth(at: 45, with: withWidth))
            $0.left.equalTo(ScaleWidth(at: 26, with: withWidth))
        }
        
        editGroupLabel.snp.makeConstraints {
            
            $0.left.equalTo(editCodeLabel)
            $0.centerY.equalTo(editGroupImage)
        }
        
        
        editGroupImage.snp.makeConstraints {
            
            $0.left.size.equalTo(editCodeImage)
            $0.top.equalTo(editCodeImage.snp.bottom).offset(ScaleWidth(at: 31.5, with: withWidth))
        }
        
        shareOTPImage.snp.makeConstraints {
            
            $0.left.size.equalTo(editCodeImage)
            $0.top.equalTo(editGroupImage.snp.bottom).offset(ScaleWidth(at: 31.5, with: withWidth))
        }
        
        shareOTPLabel.snp.makeConstraints {
            $0.left.equalTo(editCodeLabel)
            $0.top.equalTo(editGroupImage.snp.bottom).offset(ScaleWidth(at: 31.5, with: withWidth))
        }
        
        underLine.snp.makeConstraints {
            
            $0.top.equalTo(editCodeImage.snp.bottom).offset(ScaleWidth(at: 15, with: withWidth))
            $0.height.equalTo(0.5)
            $0.left.equalTo(ScaleWidth(at: 22, with: withWidth))
            $0.right.equalTo(ScaleWidth(at: -17, with: withWidth))
        }
        
        secondUnderLine.snp.makeConstraints {
            
            $0.top.equalTo(editGroupImage.snp.bottom).offset(ScaleWidth(at: 15, with: withWidth))
            $0.height.equalTo(0.5)
            $0.left.equalTo(ScaleWidth(at: 22, with: withWidth))
            $0.right.equalTo(ScaleWidth(at: -17, with: withWidth))
        }
        
        editCodeButton.snp.makeConstraints {
            
            $0.left.right.equalTo(backImageView)
            $0.top.equalTo(editCodeImage).offset(ScaleWidth(at: -10, with: withWidth))
            $0.bottom.equalTo(underLine.snp.top)
        }
        
        editGroupButton.snp.makeConstraints {
            
            $0.bottom.left.right.equalTo(backImageView)
            $0.top.equalTo(underLine.snp.bottom)
        }
        
        shareOTPButton.snp.makeConstraints {
            
            $0.bottom.left.right.equalTo(backImageView)
            $0.top.equalTo(secondUnderLine.snp.bottom)
        }
        
        editCodeButton.rx.tap.subscribe(onNext: { [weak self] in
            guard let self = self else { return }
            
            self.eventPublish.onNext(.code)
        }).disposed(by: disposedBag)
        
        editGroupButton.rx.tap.subscribe(onNext: { [weak self] in
            guard let self = self else { return }
            
            self.eventPublish.onNext(.group)
        }).disposed(by: disposedBag)
        
        let tapGest = UITapGestureRecognizer()
        addGestureRecognizer(tapGest)
        
        tapGest.rx.event.subscribe(onNext: { [weak self] gest in
            self?.isHidden = true
        }).disposed(by: disposedBag)
    }
    
    required init?(coder: NSCoder) {
        
        fatalError("init(coder:) has not been implemented")
    }
}
