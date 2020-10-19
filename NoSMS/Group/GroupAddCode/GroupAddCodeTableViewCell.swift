
import UIKit
import RxSwift
import RxCocoa


protocol GroupAddCodeTableViewCellViewModelType: BaseTableViewCellViewModelProtocol, BaseTokenListViewType {
    
    var tokenID: Data { get }
    var isSelect: BehaviorSubject<Bool> { get }
}

//MARK: 偷懶作法搶一下時間
class GroupAddCodeTableViewCellViewModel: TokenListTableViewCellViewModel, GroupAddCodeTableViewCellViewModelType {
    
    let isSelect: BehaviorSubject<Bool> = .init(value: false)
    
    override var cellFactoryType: TableViewCellFactoryType {

        .groupAddCodeTableViewCell(viewModel: self)
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

class GroupAddCodeTableViewCell: BaseTableViewCellNoGeneric {
    
    private let baseTokenListView: BaseTokenListView = .init(frame: .zero)
    
    //TODO:
    private let selectImageView: UIImageView = .init(image: .noSmsMore)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(baseTokenListView)
        contentView.addSubview(selectImageView)
        
        baseTokenListView.snp.makeConstraints {
            
            $0.top.left.right.equalToSuperview()
            $0.bottom.equalToSuperview().inset(ScaleWidth(at: 4))
        }
        
        selectImageView.snp.makeConstraints {
            
            $0.top.equalTo(ScaleWidth(at: 59))
            $0.right.equalToSuperview().inset(ScaleWidth(at: 20))
            $0.size.equalTo(ScaleWidth(at: 27))
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func bindData(viewModel: GroupAddCodeTableViewCellViewModelType) {
        baseBindData(viewModel: viewModel)
        baseTokenListView.bindData(viewModel: viewModel)
        baseTokenListView.passwordLabel.isHidden = true
        
        //TODO:
        baseTokenListView.backgroundColor = .groupCellBackCardColor
        baseTokenListView.digitsView.setColor(.tokenListHidePasswordInEditColor)
        baseTokenListView.digitsView.isHidden = false

        //TODO:
        viewModel.isSelect.map({ return $0 ? UIImage.noSMSgroupAddSelect : UIImage.noSmsNoSelected }).bind(to: selectImageView.rx.image).disposed(by: disposedBag)
    }
}
