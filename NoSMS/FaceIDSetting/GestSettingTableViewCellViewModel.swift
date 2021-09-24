
import UIKit
import RxSwift
import RxCocoa

protocol GestSettingTableViewCellViewModelType: BaseTableViewCellViewModelProtocol {
    
    var title: Observable<String> { get }
    var description: Observable<String> { get }
    var isOpenText: Observable<String> { get }
    var isOpenColor: Observable<UIColor> { get }
}

class GestSettingTableViewCellViewModel: GestSettingTableViewCellViewModelType {
    
    let title: Observable<String> = BehaviorSubject(value: "手势解锁")
    
    let description: Observable<String> = BehaviorSubject(value: "仅适用于验证码分享功能")
    
    var isOpenText: Observable<String> { GestVerificationManager.isOpenObservable.map({
        
        if $0 {
            return "已开启"
        } else {
            return "未开启"
        }
    })}
    
    var isOpenColor: Observable<UIColor> { GestVerificationManager.isOpenObservable.map({
        
        if $0 {
            return UIColor.faceIDSettingGestOpenColor
        } else {
            return UIColor.faceIDSettingGestNotOpenColor
        }
    })}
    
    let baseCellItem: BaseTableViewCellViewModelItemProtocol = BaseTableViewCellViewModelItem(cellSelectionStyle: .init(value: .none), cellHeight: ScaleWidth(at: 71), cellBackgroundColor: .init(value: .faceIDSettingBackgroundColor), cellContentViewBGColor: .init(value: .clear))
    
    var cellFactoryType: TableViewCellFactoryType { .faceIDGestVerificationInSericyTableViewCell(viewModel: self)
    }
}

class GestVerificationInSericyTableViewCell: BaseTableViewCellNoGeneric {
    
    private let titleLabel: UILabel = {
        
        let label = UILabel()
        label.setTextColor(.faceIDSettingTextColor)
            .setFont(.pingFangSemiBoldFont(size: 14))
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        
        let label = UILabel()
        label.setTextColor(.faceIDSettingDescriptionColor)
            .setFont(.pingFangSemiBoldFont(size: 14))
        return label
    }()

    private let isOpenLabel: UILabel = {
        
        let label = UILabel()
        label.setTextColor(.faceIDSettingTextColor)
            .setFont(.pingFangSemiBoldFont(size: 14))
        return label
    }()
    
    private let arrowImageView: UIImageView = {
        
        let imageView = UIImageView()
        imageView.image = .noSMSgroupCellArrow
        return imageView
    }()
    
    private let topLineView: UIView = {
        
        let view = UIView()
        view.backgroundColor = .faceIDSettingLineColor
        return view
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(isOpenLabel)
        contentView.addSubview(arrowImageView)
        contentView.addSubview(topLineView)
        
        titleLabel.snp.makeConstraints {
            
            $0.top.equalTo(ScaleWidth(at: 15))
            $0.left.equalTo(ScaleWidth(at: 20))
        }
        
        descriptionLabel.snp.makeConstraints {
            
            $0.top.equalTo(titleLabel.snp.bottom).offset(ScaleWidth(at: 1))
            $0.left.equalTo(titleLabel)
        }
        
        arrowImageView.snp.makeConstraints {
            
            $0.right.equalTo(ScaleWidth(at: -20))
            $0.centerY.equalToSuperview()
            $0.height.equalTo(ScaleWidth(at: 16.7))
            $0.width.equalTo(ScaleWidth(at: 10.7))
        }
        
        isOpenLabel.snp.makeConstraints {
            
            $0.right.equalTo(arrowImageView.snp.left).offset(ScaleWidth(at: -10))
            $0.centerY.equalTo(arrowImageView)
        }
        
        topLineView.snp.makeConstraints {
            
            $0.top.equalToSuperview()
            $0.left.right.equalToSuperview().inset(ScaleWidth(at: 15))
            $0.height.equalTo(0.5)
        }

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func bindData(viewModel: GestSettingTableViewCellViewModelType) {
        baseBindData(viewModel: viewModel)
        
        viewModel.title.bind(to: titleLabel.rx.text).disposed(by: disposedBag)
        viewModel.description.bind(to: descriptionLabel.rx.text).disposed(by: disposedBag)
        viewModel.isOpenText.bind(to: isOpenLabel.rx.text).disposed(by: disposedBag)
        viewModel.isOpenColor.bind(to: isOpenLabel.rx.textColor).disposed(by: disposedBag)
    }
}
