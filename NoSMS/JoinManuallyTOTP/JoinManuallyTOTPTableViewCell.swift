
import UIKit
import RxCocoa
import RxSwift

class JoinManuallyTOTPTextInTableViewCell<ViewModel: JoinManuallyCellTextInItemsProtocol>: BaseTableViewCell<ViewModel> {
    
    private let titleLabel: UILabel = {
        
        let label = UILabel()
        
        return label
    }()
    
    private let textField: UITextField = {
        
        let textField = UITextField()
       
        return textField
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
        
        titleLabel.snp.makeConstraints {
            
            $0.top.left.equalTo(8)
            $0.right.equalTo(-8)
        }
        
        textField.snp.makeConstraints {
            
            $0.top.equalTo(titleLabel.snp.bottom)
            $0.left.right.equalTo(titleLabel)
            $0.bottom.equalTo(-20)
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
        
        return label
    }()
    
    private let switchView: UISwitch = {
        
        let switchView = UISwitch()
       
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
            
            $0.top.left.equalTo(8)
            $0.right.equalTo(-8)
            $0.bottom.equalTo(-20)
        }
        
        switchView.snp.makeConstraints {
            
            $0.centerY.equalTo(titleLabel)
            $0.right.equalTo(-8)
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
