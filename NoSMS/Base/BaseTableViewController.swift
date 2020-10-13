
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
                 
                return ScaleWidth(at: 148)
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
    
    static func getCellViewModel(type: Type) -> TokenListTableViewCellViewModelProtocol {

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
                                                   passwordShow: token.passwordShow,
                                                   uuid: token.uuid,
                                                   addPin: token.addPin,
                                                   removePin: token.removePin)
        }
    }
}

enum TableViewCellFactoryType {
    
    case tokenListWithTime(viewModel: TokenListTableViewCellViewModel)
    case joinManuallyTextIn(viewModel: JoinManuallyCellTextInItems)
    case joinManuallySwither(viewModel: JoinManuallyCellSwitchItems)
    case photoCheckTableViewCell(viewModel: PhotoCheckTableViewCellViewModel)
    case groupTableViewCell(viewModel: GroupTableViewCellViewModel)
    case groupEditTableViewCell(viewModel: GroupEditTableViewCellViewModelType)
    case groupAddCodeTableViewCell(viewModel: GroupAddCodeTableViewCellViewModelType)
    case faceIDSettingTableViewCell(viewModel: FaceIDSettingTableViewCellViewModel)
    case faceIDSwitcherTableViewCell(viewModel:FaceIDSettingCellSwitchItems)
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

class BaseTableViewCellNoGeneric: UITableViewCell {
    
    var disposedBag: DisposeBag = .init()

    override func prepareForReuse() {
        super.prepareForReuse()
        
        disposedBag = .init()
    }
    
    func baseBindData(viewModel: BaseTableViewCellViewModelProtocol) {

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
    
    var isShareOTP = false
    
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
        return cellFactoryType.getCell(tableView: tableView, isShareOTP: isShareOTP)
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
        
        return viewModel.cellViewModels[section].sectionFooterViewModel?.sectionViewHeight ?? 0.000000001
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return viewModel.cellViewModels[section].sectionHeaderViewModel?.sectionViewHeight ?? 0.000000001
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .none
    }

    func tableView(_ tableView: UITableView, targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath, toProposedIndexPath proposedDestinationIndexPath: IndexPath) -> IndexPath {
        
        if sourceIndexPath.section != proposedDestinationIndexPath.section {
            
            return sourceIndexPath
        } else {
            
            return proposedDestinationIndexPath
        }
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
        case .groupTableViewCell:
            
            return String(describing: GroupTableViewCell<GroupTableViewCellViewModel>.self)
        case .groupEditTableViewCell:
            
            return String(describing: GroupEditTableViewCell.self)
        case .groupAddCodeTableViewCell:
            
            return String(describing: GroupAddCodeTableViewCell.self)

        case .faceIDSettingTableViewCell:
            return String(describing: FaceIDSettingTableViewCell.self)
        case .faceIDSwitcherTableViewCell:
            return String(describing: FaceIDSettingSwitchTableViewCell<FaceIDSettingCellSwitchItems>.self)

        }
    }
    var cellStyle: UITableViewCell.CellStyle {
        
        return .default
    }
    
    func getCell(tableView: UITableView, isShareOTP: Bool = false) -> UITableViewCell {

        switch self {
            
        case .tokenListWithTime(let viewModel):
            
            let cell: TokenListTableViewCell<TokenListTableViewCellViewModel>
            
            if let reuseCell = tableView.dequeueReusableCell(withIdentifier: reuseID) as? TokenListTableViewCell<TokenListTableViewCellViewModel> {
                
                cell = reuseCell
            } else {
                
                cell = TokenListTableViewCell(style: cellStyle, reuseIdentifier: reuseID)
            }
            if isShareOTP {
                cell.shareOTP()
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

        case .groupTableViewCell(let viewModel):
            
            let cell: GroupTableViewCell<GroupTableViewCellViewModel>

            if let reuseCell = tableView.dequeueReusableCell(withIdentifier: reuseID) as?             GroupTableViewCell<GroupTableViewCellViewModel> {
                
                cell = reuseCell
            } else {
                                
                cell = GroupTableViewCell<GroupTableViewCellViewModel>(style: cellStyle, reuseIdentifier: reuseID)
            }
            cell.bindData(viewModel: viewModel)
            return cell
        case .groupEditTableViewCell(let viewModel):
            
            let cell: GroupEditTableViewCell

            if let reuseCell = tableView.dequeueReusableCell(withIdentifier: reuseID) as?             GroupEditTableViewCell {
                           
                cell = reuseCell
            } else {
                                           
                cell = GroupEditTableViewCell(style: cellStyle, reuseIdentifier: reuseID)
            }
            cell.bindData(viewModel: viewModel)
            return cell
        case .groupAddCodeTableViewCell(let viewModel):
            
            let cell: GroupAddCodeTableViewCell

            if let reuseCell = tableView.dequeueReusableCell(withIdentifier: reuseID) as? GroupAddCodeTableViewCell {
                           
                cell = reuseCell
            } else {
                                           
                cell = GroupAddCodeTableViewCell(style: cellStyle, reuseIdentifier: reuseID)
            }
            cell.bindData(viewModel: viewModel)
            return cell

        case .faceIDSettingTableViewCell(let viewModel):
            let cell: FaceIDSettingTableViewCell
            if let reuseCell = tableView.dequeueReusableCell(withIdentifier: reuseID) as? FaceIDSettingTableViewCell {
                
                cell = reuseCell
            } else {
                
                cell = FaceIDSettingTableViewCell(style: cellStyle, reuseIdentifier: reuseID)
            }
            
            cell.bindData(viewModel: viewModel)
            return cell
        case .faceIDSwitcherTableViewCell(let viewModel):
            let cell: FaceIDSettingSwitchTableViewCell<FaceIDSettingCellSwitchItems>
            if let reuseCell = tableView.dequeueReusableCell(withIdentifier: reuseID) as? FaceIDSettingSwitchTableViewCell<FaceIDSettingCellSwitchItems> {
                
                cell = reuseCell
            } else {
                
                cell = FaceIDSettingSwitchTableViewCell(style: cellStyle, reuseIdentifier: reuseID)
            }
            

            cell.bindData(viewModel: viewModel)
            return cell
        }
    }
}


class BaseTableViewControllerNoGeneric: BaseViewControllerNoGeneric, UITableViewDelegate, UITableViewDataSource {
    
    let baseTableViewModel: BaseTableViewVCViewModelProtocol
    var shareOTP = false
    private(set) lazy var tableView: CustomTableView = {
      
        let tableView = CustomTableView(frame: .zero, style: self.baseTableViewModel.tableViewStyle)
        tableView.separatorStyle = .none
        return tableView
    }()
    
    init(baseTableViewModel: BaseTableViewVCViewModelProtocol) {
        self.baseTableViewModel = baseTableViewModel
        super.init(baseVCViewModel: baseTableViewModel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
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
        
        return baseTableViewModel.cellViewModels[section].numberOfRow
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cellFactoryType = baseTableViewModel.cellViewModels[indexPath.section][indexPath.row].cellFactoryType
        return cellFactoryType.getCell(tableView: tableView, isShareOTP: shareOTP)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        
        return baseTableViewModel.cellViewModels.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return baseTableViewModel.cellViewModels[indexPath.section][indexPath.row].baseCellItem.cellHeight
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        guard let headerViewModel = baseTableViewModel.cellViewModels[section].sectionHeaderViewModel else {
            
            return nil
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        guard let headerViewModel = baseTableViewModel.cellViewModels[section].sectionFooterViewModel else {
                  
            return nil
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        return baseTableViewModel.cellViewModels[section].sectionFooterViewModel?.sectionViewHeight ?? 0.000000001
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return baseTableViewModel.cellViewModels[section].sectionHeaderViewModel?.sectionViewHeight ?? 0.000000001
    }
}


class CustomTableView: UITableView {
    
    enum Event {
        
        case layoutSubview
    }
    
    let customTableViewEvent: PublishSubject<Event> = .init()
    
    var shadowViewIsHidden: Bool = false
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        for view in subviews {
            
            if #available(iOS 11, *) {
                
                if view.description.contains("UIShadowView") {
                    
                    view.isHidden = shadowViewIsHidden
                }
            } else {
                
                for iOS10View in view.subviews {
                    
                    if iOS10View.description.contains("UIShadowView") {
                        
                        iOS10View.isHidden = shadowViewIsHidden
                    }
                    
                    if let cell = iOS10View as? UITableViewCell {
                        
                        for cellSubView in cell.subviews {
                            
                            if cellSubView.description.contains("UITableViewCellEditControl") {
                                                            
                                for controlView in cellSubView.subviews {
                                    
                                    if let control = controlView as? UIImageView {
                                        
                                        control.isHidden = true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        customTableViewEvent.onNext(.layoutSubview)
    }
}
