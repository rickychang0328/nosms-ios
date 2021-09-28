

import Foundation
import RxSwift

protocol GestVerificationOpenedMeunViewControllerViewModelType: BaseTableViewVCViewModelProtocol {
    var cellType: [GestVerificationOpenedMeunViewControllerViewModelCellType] { get }
    func closeGestPassword()
    func popToBeforeVC()
}

enum GestVerificationOpenedMeunViewControllerViewModelCooridnator {
    
    case popToBeforeVC
}

enum GestVerificationOpenedMeunViewControllerViewModelCellType {
    
    case changeGestPassword
    case closePassword
    
    var title: String {
        
        switch self {
        
        case .changeGestPassword:
            return "修改手势密码"
        case .closePassword:
            return "取消手势解锁"
        }
    }
}

class GestVerificationOpenedMeunViewControllerViewModel: GestVerificationOpenedMeunViewControllerViewModelType, BaseTableViewSectionItemsProtocol {
    
    let gestVerificationManager: GestVerificationManager.Type = GestVerificationManager.self
    
    func closeGestPassword() {
        gestVerificationManager.closeGest()
    }
    
    let sectionHeaderViewModel: BaseTableViewSectionHeaderFooterViewModelProtocol? = nil
    
    let sectionFooterViewModel: BaseTableViewSectionHeaderFooterViewModelProtocol? = nil
    
    let cellType: [GestVerificationOpenedMeunViewControllerViewModelCellType]
    
    let menuViewModels: [GestVerificationMenuTableViewCellViewModelType]
    
    let cooridnator: (GestVerificationOpenedMeunViewControllerViewModelCooridnator) -> Void
    init(cooridnator: @escaping (GestVerificationOpenedMeunViewControllerViewModelCooridnator) -> Void) {
        
        let cellTypes: [GestVerificationOpenedMeunViewControllerViewModelCellType] = [.changeGestPassword, .closePassword]
        var menuViewModels: [GestVerificationMenuTableViewCellViewModelType] = []
        for cellType in cellTypes {
            
            let underLineIsHidden = (cellTypes.last == cellType)
            let menuCellViewModel = GestVerificationMenuTableViewCellViewModel(title: cellType.title, underLineIsHidden: underLineIsHidden)
            menuViewModels.append(menuCellViewModel)
        }
        self.cellType = cellTypes
        self.menuViewModels = menuViewModels
        self.cooridnator = cooridnator
    }
    
    var numberOfRow: Int {
        
        return cellType.count
    }
    
    subscript(index: Int) -> BaseTableViewCellViewModelProtocol {
        
        return menuViewModels[index]
    }
    
    var cellViewModels: [BaseTableViewSectionItemsProtocol] {
        
        [self]
    }
    
    var tableViewStyle: UITableView.Style { .grouped }
    
    let navigationItemViewModel: BaseNavigaitonItemProtocol = BaseNavigaitonItem(title: .init(value: "手势解锁"))
    
    let vcBackgroundColor: BehaviorSubject<UIColor> = .init(value: .faceIDSettingBackgroundColor)
    
    func popToBeforeVC() {
        
        cooridnator(.popToBeforeVC)
    }
}
