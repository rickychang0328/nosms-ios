//
//  BaseTableViewController.swift
//  TWAzureAuthenticator
//
//  Created by 誠帷數位科技 on 2019/11/25.
//

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
                                                   lastTime: token.lastTimeObserver)
        }
    }
}

enum TableViewCellFactoryType {
    
    case tokenList(viewModel: TokenListTableViewCellViewModel)
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
    
    private(set) lazy var tableView: UITableView = {
      
        let tableView = UITableView(frame: .zero, style: self.viewModel.tableViewStyle)
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints {
            
            $0.edges.equalToSuperview()
        }
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
        
        return viewModel.cellViewModels[section].sectionHeaderViewModel?.sectionViewHeight ?? 0
    }
}

private extension TableViewCellFactoryType {
    
    var reuseID: String {
        
        return String(describing: TokenListTableViewCell<TokenListTableViewCellViewModel>.self)
    }
    
    var cellStyle: UITableViewCell.CellStyle {
        
        return .default
    }
    
    func getCell(tableView: UITableView) -> UITableViewCell {

        switch self {
            
        case .tokenList(let viewModel):
            
            let cell: TokenListTableViewCell<TokenListTableViewCellViewModel>
            
            if let reuseCell = tableView.dequeueReusableCell(withIdentifier: reuseID) as? TokenListTableViewCell<TokenListTableViewCellViewModel> {
                
                cell = reuseCell
            } else {
                
                cell = TokenListTableViewCell(style: cellStyle, reuseIdentifier: reuseID)
            }
            
            cell.bindData(viewModel: viewModel)
            return cell
        }
    }
}


