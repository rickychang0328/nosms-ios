
class GestVerificationMenuTableViewCell: BaseTableViewCellNoGeneric {
    
    private let underline: UIView = {
       
        let view = UIView()
        view.backgroundColor = .faceIDSettingLineColor
        return view
    }()
    
    private let titleLabel: UILabel = {
        
        let label = UILabel()
        label.font = .pingFangSemiBoldFont(size: 14)
        label.textColor = .faceIDSettingTextColor
        return label
    }()
    
    private let arrowImageView: UIImageView = {
        
        let imageView = UIImageView(image: .noSMSgroupCellArrow)
        return imageView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(underline)
        contentView.addSubview(arrowImageView)
        
        titleLabel.snp.makeConstraints {
            
            $0.left.equalTo(ScaleWidth(at: 20))
            $0.centerY.equalToSuperview()
        }
        
        underline.snp.makeConstraints {
            
            $0.bottom.equalToSuperview()
            $0.left.right.equalToSuperview().inset(ScaleWidth(at: 15))
            $0.height.equalTo(0.5)
        }

        arrowImageView.snp.makeConstraints {
            
            $0.right.equalTo(ScaleWidth(at: -20))
            $0.centerY.equalToSuperview()
            $0.height.equalTo(ScaleWidth(at: 16.7))
            $0.width.equalTo(ScaleWidth(at: 10.7))
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func bindData(viewModel: GestVerificationMenuTableViewCellViewModelType) {
        baseBindData(viewModel: viewModel)
        
        titleLabel.text = viewModel.title
        underline.isHidden = viewModel.underLineIsHidden
    }
}
