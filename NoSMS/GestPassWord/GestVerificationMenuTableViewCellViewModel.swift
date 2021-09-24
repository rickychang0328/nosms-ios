
import Foundation

protocol GestVerificationMenuTableViewCellViewModelType: BaseTableViewCellViewModelProtocol {
    
    var title: String { get }
    var underLineIsHidden: Bool { get }
}

class GestVerificationMenuTableViewCellViewModel: GestVerificationMenuTableViewCellViewModelType {
            
    let title: String
    
    let underLineIsHidden: Bool
    
    let baseCellItem: BaseTableViewCellViewModelItemProtocol = BaseTableViewCellViewModelItem(cellSelectionStyle: .init(value: .none), cellHeight: ScaleWidth(at: 60), cellBackgroundColor: .init(value: .menuBackgroundColor), cellContentViewBGColor: .init(value: .clear))
    
    var cellFactoryType: TableViewCellFactoryType { .gestVerificationMenuTableViewCell(viewModel: self) }
    
    internal init(title: String, underLineIsHidden: Bool) {
        self.title = title
        self.underLineIsHidden = underLineIsHidden
    }
}
