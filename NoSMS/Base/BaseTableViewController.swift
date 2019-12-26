
import UIKit
import RxSwift
import RxCocoa

struct TableViewCellViewModelFactory {
    
    enum `Type` {
        
        case tokenList(AdapterTokenProtocol)
        
        var cellBackgroundColor: UIColor {
            
            switch self {
            case .tokenList:
      
                return .clear
            }
        }
        
        var cellContentViewBGColor: UIColor {
            
            switch self {
            case .tokenList:
                
                return .clear
            }
        }
        
        var cellHeight: CGFloat {
            
            switch self {
            case .tokenList:
                 
                return UITableView.automaticDimension
            }
        }
        
        var cellSelectionStyle: UITableViewCell.SelectionStyle {
            
            switch self {
            case .tokenList:
            
                return .none
            }
        }
        
        var baseTableViewViewModelItem: BaseTableViewCellViewModelItemProtocol {
            
            return BaseTableViewCellViewModelItem(cellSelectionStyle: .init(value: cellSelectionStyle),
                                                  cellHeight: cellHeight,
                                                  cellBackgroundColor: .init(value: cellBackgroundColor),
                                                  cellContentViewBGColor: .init(value: cellContentViewBGColor))
        }
    }
    
    static func getCellViewModel(type: Type) -> BaseTableViewCellViewModelProtocol {

        switch type {

        case .tokenList(let token):

            return TokenListTableViewCellViewModel(baseViewModelItem: type.baseTableViewViewModelItem,
                                                   name: token.name,
                                                   password: token.password,
                                                   issuer: token.issuer,
                                                   lastTime: token.lastTimeObserver,
                                                   haveSelectToDelete: token.wantDeleted,
                                                   passwordCount: token.digits,
                                                   isOnTime: token.isOnTime,
                                                   getTapPassword: token.getOnTapPassword,
                                                   refreshTime: Int(token.refreshTimes),
                                                   passwordShow: token.passwordShow)
        }
    }
}

enum TableViewCellFactoryType {
    
    case tokenListWithTime(viewModel: TokenListTableViewCellViewModel)
    case joinManuallyTextIn(viewModel: JoinManuallyCellTextInItems)
    case joinManuallySwither(viewModel: JoinManuallyCellSwitchItems)
    case photoCheckTableViewCell(viewModel: PhotoCheckTableViewCellViewModel)
}

enum TableViewHeaderFooterFactoryType {
    case tokenListHeader
}
 
protocol BaseTableViewVCViewModelProtocol: BaseVCViewModelProtocol {
    
    var cellViewModels: [BaseTableViewSectionItemsProtocol] { get }
    var tableViewStyle: UITableView.Style { get }
}

protocol BaseTableViewCellViewModelItemProtocol {
    
    var cellSelectionStyle: BehaviorSubject<UITableViewCell.SelectionStyle> { get }
    var cellHeight: CGFloat { get }
    var cellBackgroundColor: BehaviorSubject<UIColor> { get }
    var cellContentViewBGColor: BehaviorSubject<UIColor> { get }
}

class BaseTableViewCellViewModelItem: BaseTableViewCellViewModelItemProtocol {
    
    init(cellSelectionStyle: BehaviorSubject<UITableViewCell.SelectionStyle>,
         cellHeight: CGFloat,
         cellBackgroundColor: BehaviorSubject<UIColor>,
         cellContentViewBGColor: BehaviorSubject<UIColor>) {
        
        self.cellSelectionStyle = cellSelectionStyle
        self.cellHeight = cellHeight
        self.cellBackgroundColor = cellBackgroundColor
        self.cellContentViewBGColor = cellContentViewBGColor
    }
    
    
    let cellSelectionStyle: BehaviorSubject<UITableViewCell.SelectionStyle>
    
    var cellHeight: CGFloat
    
    let cellBackgroundColor: BehaviorSubject<UIColor>
    
    let cellContentViewBGColor: BehaviorSubject<UIColor>
}

protocol BaseTableViewCellViewModelProtocol {
    
    var baseCellItem: BaseTableViewCellViewModelItemProtocol { get }
    var cellFactoryType: TableViewCellFactoryType { get }

}

protocol BaseTableViewSectionHeaderFooterViewModelProtocol {
    
    var sectionViewHeight: CGFloat { get }
    var sectionViewBackgroundColor: BehaviorSubject<UIColor> { get }
    var sectionViewFactoryType: TableViewHeaderFooterFactoryType { get }
}

protocol BaseTableViewSectionItemsProtocol: AnyObject {
    
    var sectionHeaderViewModel: BaseTableViewSectionHeaderFooterViewModelProtocol? { get }
    var sectionFooterViewModel: BaseTableViewSectionHeaderFooterViewModelProtocol? { get }
    var numberOfRow: Int { get }
    subscript(index: Int) -> BaseTableViewCellViewModelProtocol { get }
}

class BaseTableViewCell<ViewModel: BaseTableViewCellViewModelProtocol>: UITableViewCell {
    
    var disposedBag: DisposeBag = .init()

    override func prepareForReuse() {
        super.prepareForReuse()
        
        disposedBag = .init()
    }
    
    func bindData(viewModel: ViewModel) {

        viewModel.baseCellItem.cellSelectionStyle
            .bind(to: rx.selectionStyle)
            .disposed(by: disposedBag)
        
        viewModel.baseCellItem.cellBackgroundColor
            .bind(to: rx.backgroundColor)
            .disposed(by: disposedBag)
        
        viewModel.baseCellItem.cellContentViewBGColor
            .bind(to: contentView.rx.backgroundColor)
            .disposed(by: disposedBag)
        
    }
}

extension Reactive where Base: UITableViewCell {
    
    var selectionStyle: Binder<UITableViewCell.SelectionStyle> {
        
        return Binder(self.base) { view, selectionStyle in
            view.selectionStyle = selectionStyle
        }
    }
}

class BaseTableViewController<ViewModel: BaseTableViewVCViewModelProtocol>: BaseViewController<ViewModel>, UITableViewDelegate, UITableViewDataSource {
    
    lazy var tableView: UITableView = {
      
        let tableView = UITableView(frame: .zero, style: self.viewModel.tableViewStyle)
        tableView.separatorStyle = .none
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            
            $0.edges.equalToSuperview()
        }
        
        if #available(iOS 11, *) {

        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 20
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return viewModel.cellViewModels[section].numberOfRow
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellFactoryType = viewModel.cellViewModels[indexPath.section][indexPath.row].cellFactoryType
        return cellFactoryType.getCell(tableView: tableView)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return viewModel.cellViewModels.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return viewModel.cellViewModels[indexPath.section][indexPath.row].baseCellItem.cellHeight
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        guard let headerViewModel = viewModel.cellViewModels[section].sectionHeaderViewModel else {
            
            return nil
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        guard let headerViewModel = viewModel.cellViewModels[section].sectionFooterViewModel else {
                  
            return nil
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        return viewModel.cellViewModels[section].sectionFooterViewModel?.sectionViewHeight ?? 0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return viewModel.cellViewModels[section].sectionHeaderViewModel?.sectionViewHeight ?? 0.000000001
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }
    
    
}

private extension TableViewCellFactoryType {
    
    var reuseID: String {
        
        switch self {
        
        case .tokenListWithTime:
            return String(describing: TokenListTableViewCell<TokenListTableViewCellViewModel>.self)
            
        case .joinManuallyTextIn:
            return String(describing: JoinManuallyTOTPTextInTableViewCell<JoinManuallyCellTextInItems>.self)
            
        case .joinManuallySwither:
            return String(describing: JoinManuallyTOTPSwitchTableViewCell<JoinManuallyCellSwitchItems>.self)

        case .photoCheckTableViewCell:
            return String(describing: PhotoCheckTableViewCell.self)
        }
    }
    
    var cellStyle: UITableViewCell.CellStyle {
        
        return .default
    }
    
    func getCell(tableView: UITableView) -> UITableViewCell {

        switch self {
            
        case .tokenListWithTime(let viewModel):
            
            let cell: TokenListTableViewCell<TokenListTableViewCellViewModel>
            
            if let reuseCell = tableView.dequeueReusableCell(withIdentifier: reuseID) as? TokenListTableViewCell<TokenListTableViewCellViewModel> {
                
                cell = reuseCell
            } else {
                
                cell = TokenListTableViewCell(style: cellStyle, reuseIdentifier: reuseID)
            }
            
            cell.bindData(viewModel: viewModel)
            return cell
            
        case .joinManuallyTextIn(let viewModel):
            
            let cell: JoinManuallyTOTPTextInTableViewCell<JoinManuallyCellTextInItems>
            
            if let reuseCell = tableView.dequeueReusableCell(withIdentifier: reuseID) as? JoinManuallyTOTPTextInTableViewCell<JoinManuallyCellTextInItems> {
                
                cell = reuseCell
            } else {
                
                cell = JoinManuallyTOTPTextInTableViewCell(style: cellStyle, reuseIdentifier: reuseID)
            }
            
            cell.bindData(viewModel: viewModel)
            return cell
        case .joinManuallySwither(let viewModel):
            
            let cell: JoinManuallyTOTPSwitchTableViewCell<JoinManuallyCellSwitchItems>
            
            if let reuseCell = tableView.dequeueReusableCell(withIdentifier: reuseID) as? JoinManuallyTOTPSwitchTableViewCell<JoinManuallyCellSwitchItems> {
                
                cell = reuseCell
            } else {
                
                cell = JoinManuallyTOTPSwitchTableViewCell(style: cellStyle, reuseIdentifier: reuseID)
            }
            
            cell.bindData(viewModel: viewModel)
            return cell
        case .photoCheckTableViewCell(let viewModel):
            let cell: PhotoCheckTableViewCell
            
            if let reuseCell = tableView.dequeueReusableCell(withIdentifier: reuseID) as? PhotoCheckTableViewCell {
                           
                cell = reuseCell
            } else {
                           
                cell = PhotoCheckTableViewCell(style: cellStyle, reuseIdentifier: reuseID)
            }
                
            cell.bindData(viewModel: viewModel)
            return cell
        }
    }
}


