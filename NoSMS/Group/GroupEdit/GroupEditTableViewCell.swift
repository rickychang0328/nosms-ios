
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
    
    private func searchControlView() {
        
        for view in subviews {
            //MARK: iOS 10 以下找這個
            if view.description.contains("UITableViewCellDeleteConfirmationView") {
                        
                view.backgroundColor = .groupEditCellDeleteActionColor
                       

                view.frame = .init(origin: view.frame.origin, size: .init(width: view.frame.width, height: baseTokenView.frame.height))
                
                       
                let custom = GroupEditDeleteActionView(frame: .zero)
                       
                for button in view.subviews {
                    
                    if let buttonType = button as? UIButton {
                        
                        buttonType.setTitle("", for: .normal)
                        buttonType.setTitle("", for: .selected)
                        buttonType.setTitle("", for: .highlighted)
                    }
                    button.backgroundColor = .clear
                    view.addSubview(custom)
                    view.sendSubviewToBack(custom)
                    custom.snp.makeConstraints {
                               
                        $0.edges.equalTo(button)
                    }
                }
            }
        }
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)

        searchControlView()
    }
    
    override func didAddSubview(_ subview: UIView) {
        super.didAddSubview(subview)

        searchControlView()
    }
}
