
import UIKit
import RxCocoa
import RxSwift

protocol GroupAddCodeVCViewModelType: BaseTableViewVCViewModelProtocol, BaseSearchVCViewModelType {
    
    var eventObserver: Observable<GroupAddCodeVCViewModel.Event> { get }
    var actionEnable: Observable<Bool> { get }
    
    func addAction()
    func itemSelect(indexPath: IndexPath)
}

class GroupAddCodeVCViewModel: BaseVCViewModel, GroupAddCodeVCViewModelType {
    
    var actionEnable: Observable<Bool> {
        return _actionEnable.asObservable()
    }
    
    private let _actionEnable: BehaviorSubject<Bool> = .init(value: false)
    
    var eventObserver: Observable<GroupAddCodeVCViewModel.Event> {
        
        return eventPublishSubject.asObservable()
    }
    
    private let eventPublishSubject: PublishSubject<Event> = .init()
    
    private let groupCode: [Data]
    
    enum Event {
        
        case reloadData
    }
    
    internal init(groupCode: [Data],
                  tokenStore: TokenStoreProtocol = KeychainTokenStore.shared,
                  addTokenIDs: BehaviorSubject<[Data]>,
                  navigationItemViewModel: BaseNavigaitonItemProtocol = BaseNavigaitonItem(title: BehaviorSubject<String>(value: "添加验证码"))) {
        self.groupCode = groupCode
        self.tokenStore = tokenStore
        self.addTokenIDs = addTokenIDs
        super.init(navigationItem: navigationItemViewModel, backgroundColor: .groupAddCodeVCBackGroundColor)
        
        tokenStore.persistentTokensBehavior.map({$0.map{ GroupAddCodeTableViewCellViewModel(token: $0)} })
            .subscribe(onNext: { [weak self] tokens in
                guard let self = self else { return }
                
                let noInGroupCode = tokens.filter({!self.groupCode.contains($0.tokenID)})
                self.tokensViewModel = noInGroupCode
                self.supputPin.setupTokens(tokens: noInGroupCode)
                self.eventPublishSubject.onNext(.reloadData)
            }).disposed(by: disposedBag)
    }
    
    private let tokenStore: TokenStoreProtocol
    
    private let addTokenIDs: BehaviorSubject<[Data]>
    
    private var addIDs: [Data] = [] {
        
        didSet {
            
            _actionEnable.onNext(!addIDs.isEmpty)
        }
    }
    
    func addAction() {
        
        addTokenIDs.onNext(addIDs)
    }
    
    private var tokensViewModel: [GroupAddCodeTableViewCellViewModelType] = []
    
    func itemSelect(indexPath: IndexPath) {
        
        let realIndex = supputPin.sections[indexPath.section].getRealIndex(afterSearchIndex: indexPath.row)
        let id = supputPin.sections[indexPath.section].rowItems[realIndex].tokenID
        
        let havebeenSelect: Bool
        
        if let idIndex = addIDs.firstIndex(of: id) {
            
            addIDs.remove(at: idIndex)
            havebeenSelect = true
        } else {
            
            addIDs.append(id)
            havebeenSelect = false
        }
        
        let tokenViewModel = tokensViewModel.first(where: { $0.tokenID == id})
        tokenViewModel?.isSelect.onNext(!havebeenSelect)
    }
    
    private let supputPin: TokenListSupportPin = TokenListSupportPin()
    
    var cellViewModels: [BaseTableViewSectionItemsProtocol] {
        
        return supputPin.sections
    }
    
    var tableViewStyle: UITableView.Style { .grouped }
    
    func searchText(input: String) {
        
        supputPin.setSearchString(input: input)
        eventPublishSubject.onNext(.reloadData)
    }
}


class GroupAddCodeViewController: BaseSearchViewController {
    
    private let rightNavigationItem: UIBarButtonItem = {
        
        let barButton = UIBarButtonItem(title: "添加", style: .done, target: nil, action: nil)
        barButton.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.pingFangMediumFont(size: 14)], for: .normal)
        barButton.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.pingFangMediumFont(size: 14)], for: .disabled)
        barButton.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.pingFangMediumFont(size: 14)], for: .selected)
        return barButton
    }()

    private let viewModel: GroupAddCodeVCViewModelType
    
    private let baseTableViewVC: BaseTableViewControllerNoGeneric
    
    init(viewModel: GroupAddCodeVCViewModelType) {
        
        self.viewModel = viewModel
        self.baseTableViewVC = .init(baseTableViewModel: viewModel)
        super.init(baseSearchViewModel: viewModel)
        addChild(baseTableViewVC)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = rightNavigationItem
        underSearchView.addSubview(baseTableViewVC.view)
        
        viewModel.actionEnable.bind(to: rightNavigationItem.rx.isEnabled).disposed(by: disposedBag)
        
        baseTableViewVC.view.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        baseTableViewVC.tableView.rx.itemSelected
            .subscribe(onNext: viewModel.itemSelect(indexPath:))
            .disposed(by: disposedBag)
        rightNavigationItem.rx.tap.subscribe(onNext: { [weak self] in
            
            guard let self = self else { return }
            self.viewModel.addAction()
            self.navigationController?.popViewController(animated: true)
            
            }).disposed(by: disposedBag)
        
        baseTableViewVC.tableView.rx.didScroll.subscribe(onNext: { [weak self] in
            
            guard let self = self else { return }
            let tableView = self.baseTableViewVC.tableView
            if !(self.searchTextField.text?.isEmpty ?? true) || self.searchTextField.isFirstResponder {
                
                return
            }
            
            if tableView.contentSize.height > tableView.bounds.height,
                tableView.panGestureRecognizer.translation(in: tableView).y < 0 ||
                    tableView.contentOffset.y > tableView.panGestureRecognizer.translation(in: tableView).y {
                
                self.dissmissSearchTextAnimation()
            } else if tableView.contentOffset.y <= 0 {
                
                self.showSearchTextAnimation()
            }
        }).disposed(by: disposedBag)
        
        viewModel.eventObserver.subscribe(onNext: { [weak self] event in
            guard let self = self else { return }
            switch event {
                
            case .reloadData:
                self.baseTableViewVC.tableView.reloadData()
            }
        }).disposed(by: disposedBag)
    }
}
