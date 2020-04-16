
import UIKit
import RxSwift
import RxCocoa

protocol GroupTableViewCellViewModelType: BaseTableViewCellViewModelProtocol {
    
    var title: String { get }
    var isEditing: Observable<Bool> { get }
}


class GroupTableViewCellViewModel: GroupTableViewCellViewModelType {
    
    let isEditing: Observable<Bool>
    
    let title: String
    
    let baseCellItem: BaseTableViewCellViewModelItemProtocol
    
    var cellFactoryType: TableViewCellFactoryType {
        
        return .groupTableViewCell(viewModel: self)
    }
    
    internal init(isEditing: Observable<Bool>,
                  title: String,
                  baseCellItem: BaseTableViewCellViewModelItemProtocol = BaseTableViewCellViewModelItem(
        cellSelectionStyle: BehaviorSubject<UITableViewCell.SelectionStyle>(value: .none),
        cellHeight: ScaleWidth(at: 70),
        cellBackgroundColor: BehaviorSubject<UIColor>(value: .clear),
        cellContentViewBGColor: BehaviorSubject<UIColor>(value: .clear))) {
        
        self.isEditing = isEditing
        self.title = title
        self.baseCellItem = baseCellItem
    }
}

class GroupTableViewCell<ViewModel: GroupTableViewCellViewModelType>: BaseTableViewCell<ViewModel> {
    
    private let backCardView: UIView = {
       
        let view = NeverClearColorView()
        view.addCornerRadius(at: ScaleWidth(at: 6))
            .setBackgroundColor(.groupBackCardColor)
        view.clipsToBounds = false
        view.layer.shadowOffset = .init(width: 0, height: ScaleWidth(at: 1))
        view.layer.shadowOpacity = 0.07
        return view
    }()
    
    private let arrowImageView: UIImageView = {
       
        let view = UIImageView(image: .noSMSgroupCellArrow)
        return view
    }()
    
    private let titleLabel: UILabel = {
        
        let label = UILabel()
        label.setFont(.pingFangMediumFont(size: 16))
            .setTextColor(.groupCellTitleColor)
        return label
    }()
    
    private let moveImageView: UIImageView = .init(image: .noSmsMoveCell)
    
    private let deleteButtomImage: UIImageView = .init(image: .noSMSgroupMenuRemoveButton)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(backCardView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(arrowImageView)
        contentView.addSubview(moveImageView)
        contentView.addSubview(deleteButtomImage)
        
        backCardView.snp.makeConstraints {
            
            $0.top.equalToSuperview()
            $0.left.equalToSuperview()
            $0.right.equalTo(self)
            $0.height.equalTo(ScaleWidth(at: 60))
        }
        
        titleLabel.snp.makeConstraints {
            $0.left.equalTo(backCardView).offset(
                ScaleWidth(at: 20))
            $0.right.equalTo(arrowImageView.snp.left).inset(ScaleWidth(at: 20))
            $0.centerY.equalTo(backCardView)
        }
        
        arrowImageView.snp.makeConstraints {
            
            $0.centerY.equalTo(backCardView)
            $0.right.equalTo(backCardView).inset(ScaleWidth(at: 16))
            $0.width.equalTo(ScaleWidth(at: 8.25))
            $0.height.equalTo(ScaleWidth(at: 16.5))
        }
        
        moveImageView.snp.makeConstraints {
            
            $0.centerY.equalTo(backCardView)
            $0.width.equalTo(ScaleWidth(at: 18))
            $0.height.equalTo(ScaleWidth(at: 13.5))
            $0.right.equalTo(backCardView).offset(ScaleWidth(at: -15))
        }
        
        deleteButtomImage.snp.makeConstraints {
            
            $0.centerY.equalTo(backCardView)
            $0.right.equalTo(backCardView.snp.left).offset(ScaleWidth(at: -17))
            $0.size.equalTo(ScaleWidth(at: 18))
        }
    }
        
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func bindData(viewModel: ViewModel) {
        super.bindData(viewModel: viewModel)
        
        titleLabel.text = viewModel.title
        
        viewModel.isEditing.subscribe(onNext: { [weak self] isEditing in
            guard let self = self else { return }
            self.setupImageView(isEditing: isEditing)
        }).disposed(by: disposedBag)
    }
    
    private func searchControlView() {
        
        for view in subviews {
            
            for view in self.subviews {
                
                if view.description.contains("UITableViewCellReorderControl") {

                    let imageOfReorder = view.subviews[0] as? UIImageView
                    imageOfReorder?.image = nil
                }
            }
            
            if view.description.contains("UITableViewCellEditControl") {

                view.center.y = backCardView.center.y
                
                for controlView in view.subviews {
                    
                    if let control = controlView as? UIImageView {
                        
                        control.image = nil
                        
                        uiTableViewCellEditControlobserver = control.observe(\.image, options: [.new]){ [weak control] (view, value) in

                            if control?.image != nil {

                                control?.image = nil
                            }
                        }
                    }
                }
            }
              
            
            //MARK: iOS 10 以下找這個
            if view.description.contains("UITableViewCellDeleteConfirmationView") {
                        
                view.backgroundColor = .clear
                view.frame = .init(origin: .init(x: view.frame.origin.x + ScaleWidth(at: 100), y: view.frame.origin.y), size: .init(width: view.frame.width, height: backCardView.frame.height))
                view.addCornerRadius(at: ScaleWidth(at: 6))
                let custom = GroupDeleteActionView(frame: .zero)
                       
                for button in view.subviews {

                    custom.addCornerRadius(at: 6)
                    custom.backgroundColor = .groupEditCellDeleteActionColor
                    if let buttonType = button as? UIButton {
                        
                        buttonType.setTitle("", for: .normal)
                        buttonType.setTitle("", for: .selected)
                        buttonType.setTitle("", for: .highlighted)
                    }
                    button.backgroundColor = .clear
                    view.addSubview(custom)
                    view.sendSubviewToBack(custom)
                    custom.snp.makeConstraints {
                        $0.top.bottom.right.equalToSuperview()
                        $0.left.equalToSuperview().offset(ScaleWidth(at: 10))
                    }
                }
            }
        }
    }
    
    private var uiTableViewCellEditControlobserver: NSKeyValueObservation?
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        searchControlView()
        if !editing {
            
            uiTableViewCellEditControlobserver = nil
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        searchControlView()

    }

    private func setupImageView(isEditing: Bool) {
        
        moveImageView.isHidden = !isEditing
        arrowImageView.isHidden = isEditing
    }
}
