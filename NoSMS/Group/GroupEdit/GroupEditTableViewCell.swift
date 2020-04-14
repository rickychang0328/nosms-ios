
import UIKit
import RxSwift
import RxCocoa


protocol GroupEditTableViewCellViewModelType: BaseTableViewCellViewModelProtocol, BaseTokenListViewType {
    
}

class GroupEditTableViewCellViewModel: TokenListTableViewCellViewModel, GroupEditTableViewCellViewModelType {
        
    override var cellFactoryType: TableViewCellFactoryType {
        
        return .groupEditTableViewCell(viewModel: self)
    }
    
    init(token: AdapterTokenProtocol) {
        
        super.init(baseViewModelItem: BaseTableViewCellViewModelItem(cellSelectionStyle: .init(value: .none),
                                                                     cellHeight: ScaleWidth(at: 148),
                                                                     cellBackgroundColor: .init(value: .clear),
                                                                     cellContentViewBGColor: .init(value: .clear)),
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

class GroupEditTableViewCell: BaseTableViewCellNoGeneric {
    
    private let baseTokenView: BaseTokenListView = .init(frame: .zero)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(baseTokenView)
        
        baseTokenView.snp.makeConstraints {
            
            $0.top.left.right.equalToSuperview()
            $0.bottom.equalTo(ScaleWidth(at: -4))
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func bindData(viewModel: GroupEditTableViewCellViewModelType) {
        
        baseBindData(viewModel: viewModel)
        baseTokenView.bindData(viewModel: viewModel)
        baseTokenView.passwordLabel.isHidden = true
        baseTokenView.digitsView.setColor(.tokenListHidePasswordInEditColor)
        baseTokenView.digitsView.isHidden = false
        baseTokenView.backgroundColor = .groupCellBackCardColor
    }
    
}
