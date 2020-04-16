
import UIKit
import RxSwift
import RxCocoa

protocol BaseSearchVCViewModelType: BaseVCViewModelProtocol {
    
    func searchText(input: String)
}

class BaseSearchViewController: BaseViewControllerNoGeneric, UITextFieldDelegate {
    
    private(set) lazy var searchTextField: CustomTextField = {
        
        let textField = CustomTextField(frame: .zero)
        textField.textColor = .tokenListSearchTextFieldTextColor
        textField.backgroundColor = .tokenListSearchTextFieldBackgroundColor
        textField.placeholder = "搜索"
        textField.font = .pingFangMediumFont(size: 15)
        textField.addCornerRadius(at: ScaleWidth(at: 6))

        textField.addCustomLeftView(image: .noSmsSearch, textViewMode: .always)
        textField.addCustomClearButton()
        textField.clearButton?.rx.tap.subscribe(onNext: { [weak self] in

            self?.cleanTextField()
        }).disposed(by: self.disposedBag)
        textField.returnKeyType = .search

        textField.delegate = self
        return textField
    }()
    
    let resetSearchButton: UIButton = {
        
        let button = UIButton()
        button.setTitle("取消", for: .normal)
        button.setTitleColor( .tokenListResetSearchButton, for: .normal)
        button.titleLabel?.font = .pingFangMediumFont(size: 15)
        button.isHidden = true
        return button
    }()
    
    let underSearchView: UIView = UIView()
    
    private let baseSearchViewModel: BaseSearchVCViewModelType
    
    init(baseSearchViewModel: BaseSearchVCViewModelType) {
        
        self.baseSearchViewModel = baseSearchViewModel
        super.init(baseVCViewModel: baseSearchViewModel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(searchTextField)
        view.addSubview(resetSearchButton)
        view.addSubview(underSearchView)
        
        searchTextField.snp.makeConstraints {
            
            $0.top.equalToSuperview().offset(ScaleWidth(at: 8))
            $0.left.equalToSuperview().offset(ScaleWidth(at: 12))
            $0.right.equalTo(ScaleWidth(at: -12))
            $0.height.equalTo(ScaleWidth(at: 40))
            $0.bottom.equalTo(underSearchView.snp.top).offset(ScaleWidth(at: -8))
        }
        
        resetSearchButton.snp.makeConstraints {
            
            $0.top.bottom.equalTo(searchTextField)
            $0.right.equalToSuperview().offset(ScaleWidth(at: -12))
        }
        
        underSearchView.snp.makeConstraints {
            
            $0.bottom.left.right.equalToSuperview()
        }
        
        searchTextField.rx.text
            .orEmpty
            .subscribe(onNext: baseSearchViewModel.searchText(input:))
            .disposed(by: disposedBag)

        //MARK: 不知道要不要用取消
//        searchTextField.rx.text.subscribe(onNext: { [weak self] text in
//
//            self?.setupViewInSearchStatus()
//
//            }).disposed(by: disposedBag)
        
        resetSearchButton.rx.tap.subscribe(onNext: { [weak self] in
            
            self?.resetSearch()
            
            }).disposed(by: disposedBag)
    }
    
    func dissmissSearchTextAnimation() {
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            UIView.animate(withDuration: 0.3,
                           delay: 0.0,
                           usingSpringWithDamping: 1.0,
                           initialSpringVelocity: 5.0,
                           animations: {
                            
                            self.searchTextField.snp.updateConstraints{ item in
                                
                                item.top.equalTo(ScaleWidth(at: 0))
                                item.height.equalTo(ScaleWidth(at: 0))
                                item.bottom.equalTo(self.underSearchView.snp.top).inset(ScaleWidth(at: 0))
                            }
                            self.searchTextField.isHidden = true
                            self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    func showSearchTextAnimation() {
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            UIView.animate(withDuration: 0.3,
                           delay: 0.0,
                           usingSpringWithDamping: 1.0,
                           initialSpringVelocity: 5.0,
                           animations: {
                            
                            self.searchTextField.snp.updateConstraints{ item in
                                
                                item.top.equalTo(ScaleWidth(at: 8))
                                item.height.equalTo(ScaleWidth(at: 40))
                            item.bottom.equalTo(self.underSearchView.snp.top).offset(ScaleWidth(at: -8))
                            }
                            self.searchTextField.isHidden = false
                            self.view.layoutIfNeeded()
            }, completion: nil)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField.isFirstResponder {
            
            textField.resignFirstResponder()
            setupViewInSearchStatus()
        }
        return true
    }
    
    private func cleanTextField() {
        
        searchTextField.text = ""
        baseSearchViewModel.searchText(input: "")
    }
    
    private func resetSearch() {
         
         cleanTextField()
         if searchTextField.isFirstResponder {
             
             searchTextField.resignFirstResponder()
         }
         setupViewInSearchStatus()
    }
    
    private func setupViewInSearchStatus() {
        
        let textFieldWidth: CGFloat
        let resetSearchButtonIsHidden: Bool
        
        if !(searchTextField.text?.isEmpty ?? true) || searchTextField.isFirstResponder {
                
            textFieldWidth = ScaleWidth(at: -52)
            resetSearchButtonIsHidden = false
        } else {
            
            textFieldWidth = ScaleWidth(at: -12)
            resetSearchButtonIsHidden = true
        }
        
        searchTextField.changeRight(to: textFieldWidth)
        resetSearchButton.isHidden = resetSearchButtonIsHidden
    }
}

