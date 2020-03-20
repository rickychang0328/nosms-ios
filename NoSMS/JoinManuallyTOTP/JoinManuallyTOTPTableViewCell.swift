
import UIKit
import RxCocoa
import RxSwift

class JoinManuallyTOTPTextInTableViewCell<ViewModel: JoinManuallyCellTextInItemsProtocol>: BaseTableViewCell<ViewModel> {
    
    private let titleLabel: UILabel = {
        
        let label = UILabel()
        label.setFont(.pingFangSemiBoldFont(size: 14))
            .setTextColor(.manuallyTOTPTitleColor)
        
        return label
    }()
    
    private let textField: UITextField = {
        
        let textField = UITextField()
        
        textField.font = .pingFangMediumFont(size: 15)
        textField.textColor = .manuallyTOTPTitleColor
        return textField
    }()
    
    private let textFieldUnderLine: UIView = {
        
        let view = UIView()

//        view.setBackgroundColor(.textFieldUnderLineColor)
        view.setBackgroundColor(.manuallyTOTPTextFieldUnderLineColor)
        return view
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        layoutView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func layoutView() {
        
        addSubview(titleLabel)
        addSubview(textField)
        addSubview(textFieldUnderLine)
        
        titleLabel.snp.makeConstraints {
            
            $0.top.equalTo(ScaleWidth(at: 30))
            $0.left.equalTo(ScaleWidth(at: 35))
            $0.right.equalTo(ScaleWidth(at: -35))
        }
    
        textField.snp.makeConstraints {
            
            $0.top.equalTo(titleLabel.snp.bottom).offset(ScaleWidth(at: 14))
            $0.left.right.equalTo(titleLabel)
            $0.bottom.equalTo(ScaleWidth(at: -16))
//            $0.height.equalTo(ScaleWidth(at: 21))
        }
        
        textFieldUnderLine.snp.makeConstraints {
            
            $0.left.right.equalTo(titleLabel)
            $0.top.equalTo(textField.snp.bottom).offset(ScaleWidth(at: 11))
            $0.height.equalTo(0.5)
        }
    }
    
    override func bindData(viewModel: ViewModel) {
        super.bindData(viewModel: viewModel)
        
        titleLabel.text = viewModel.title
        textField.placeholder = viewModel.textfieldPlaceHolder
        
        viewModel.inputString
                  .asObserver()
                  .bind(to: textField.rx.text)
                  .disposed(by: disposedBag)
        
        textField.rx.text
            .orEmpty
            .distinctUntilChanged()
            .bind(to: viewModel.inputString)
            .disposed(by: disposedBag)
    }
}


class JoinManuallyTOTPSwitchTableViewCell<ViewModel: JoinManuallyCellSwitchItemsProtocol>: BaseTableViewCell<ViewModel> {
    
    private let titleLabel: UILabel = {
        
        let label = UILabel()
        label.setTextColor(.textBlackColor)
            .setFont(.pingFangSemiBoldFont(size: 14))
        return label
    }()
    
    private let switchView: UISwitch = {
        
        let switchView = UISwitch()
        switchView.onTintColor = UIColor(red: 36/255, green: 205/255, blue: 132/255, alpha: 1)
        return switchView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        layoutView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func layoutView() {
        
        addSubview(titleLabel)
        addSubview(switchView)
        
        titleLabel.snp.makeConstraints {
            
            $0.top.equalTo(ScaleWidth(at: 30))
            $0.left.equalTo(ScaleWidth(at: 35))
            $0.right.equalTo(ScaleWidth(at: -35))
        }
        
        switchView.snp.makeConstraints {
            
            $0.width.equalTo(ScaleWidth(at: 50))
            $0.height.equalTo(ScaleWidth(at: 25))
            $0.centerY.equalTo(titleLabel)
            $0.right.equalTo(ScaleWidth(at: -35))
        }
    }
    
    override func bindData(viewModel: ViewModel) {
        super.bindData(viewModel: viewModel)
        
        titleLabel.text = viewModel.title
                
        viewModel.switcher.bind(to: switchView.rx.isOn).disposed(by: disposedBag)
        
        switchView.rx.isOn
            .distinctUntilChanged()
            .bind(to: viewModel.switcher)
            .disposed(by: disposedBag)

    }
}
