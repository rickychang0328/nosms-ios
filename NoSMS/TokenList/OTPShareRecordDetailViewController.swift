//
//  OTPShareRecordDetailViewController.swift
//  NoSMS
//
//  Created by Andy LI on 2020/11/4.
//

import UIKit
import RxSwift
import RxCocoa

class OTPShareRecordDetailViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    private let disposeBag: DisposeBag = .init()
    var tableView = UITableView()
    
    var otpValueDicArray = [OTPAccountData]()
    var navTitle = ""
    var otpValueFilterDicArray = [OTPAccountData]()
    let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .getColor(red: 41, green: 44, blue: 68, alpha: 1)
        view.addCornerRadius(at: 10)
        return view
    }()
    
    private lazy var searchTextField: UITextField = {
        
        let textField = CustomTextField(frame: .zero)
        textField.textColor = .otpShareSearchTextColor
        textField.backgroundColor = .tokenListSearchTextFieldBackgroundColor
        textField.placeholder = "搜索"
        textField.font = .pingFangMediumFont(size: 15)
        textField.addCornerRadius(at: ScaleWidth(at: 6))
        
        textField.addCustomLeftView(image: .noSmsSearch, textViewMode: .always)
        textField.addCustomClearButton()
        textField.clearButton?.rx.tap.subscribe(onNext: { [weak self] in
            
            self?.cleanTextField()
        }).disposed(by: self.disposeBag)
        textField.returnKeyType = .search
        
        textField.delegate = self
        return textField
    }()
    
    private let resetSearchButton: UIButton = {
           
        let button = UIButton()
        button.setTitle("取消", for: .normal)
        button.setTitleColor( .tokenListResetSearchButton, for: .normal)
        button.titleLabel?.font = .pingFangMediumFont(size: 15)
        button.isHidden = true
        return button
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        setNavigate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNavigate()
        self.navigationController?.navigationBar.topItem?.title = ""
        self.navigationItem.title = navTitle
        tableView.register(ShareOTPRecordDetailTableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        view.addSubview(searchTextField)
        view.addSubview(tableView)
        view.addSubview(resetSearchButton)
        searchTextField.snp.makeConstraints {
            $0.top.equalToSuperview().offset(ScaleWidth(at: 8))
            $0.left.equalToSuperview().offset(12)
            $0.right.equalToSuperview().offset(-12)
            $0.height.equalTo(40)
        }
        
        tableView.snp.makeConstraints {
            $0.top.equalTo(searchTextField.snp.bottom).offset(ScaleWidth(at: 17))
            $0.left.equalToSuperview()
            $0.right.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
        
        resetSearchButton.snp.makeConstraints {
            
            $0.top.bottom.equalTo(searchTextField)
            $0.right.equalToSuperview().offset(ScaleWidth(at: -12))
        }
        
        resetSearchButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.resetSearch()
            }).disposed(by: disposeBag)
        
        tableView.rx.didScrollToTop
            .subscribe(onNext: {[weak self] in
                guard let self = self else { return }
                if (self.searchTextField.text?.isEmpty ?? true){
                    self.showSearchTextAnimation()
                }
            }).disposed(by: disposeBag)
        
        tableView.rx.didScroll
            .subscribe { [weak self] _ in
                guard let self = self else { return }
                SwipeManager.shared.swipeOff()
                if (self.searchTextField.text?.isEmpty ?? true){
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.showSearchTextAction(tableView: self.tableView)
                    }
                }
            }.disposed(by: disposeBag)
        
        searchTextField.rx.text
            .orEmpty
            .distinctUntilChanged()
            .subscribe(onNext: { [weak self] text in
                guard let self = self else { return }
                self.textFieldDidChange(text: text)
            }).disposed(by: disposeBag)
        
        
    }
    
    private func showSearchTextAction(tableView: UITableView){
        
        if !self.searchTextField.isEditing && tableView.contentSize.height > tableView.frame.height {
            if tableView.panGestureRecognizer.translation(in: tableView).y < 0 || ( tableView.contentOffset.y > tableView.panGestureRecognizer.translation(in: tableView).y) {
                
                DispatchQueue.main.async {[weak self] in
                    guard let self = self else {return}
                    UIView.animate(withDuration: 0.3, delay: 0.0,
                                   usingSpringWithDamping: 1.0, initialSpringVelocity: 5.0,
                                   animations: {
                                    self.searchTextField.snp.updateConstraints{item in
                                        item.top.equalTo(ScaleWidth(at: 0))
                                        item.height.equalTo(ScaleWidth(at: 0))
                                    }
                                    self.searchTextField.isHidden = true
                                    self.view.layoutIfNeeded()
                    },
                                   completion: nil
                    )
                    
                    self.tableView.snp.updateConstraints {
                        $0.top.equalTo(self.searchTextField.snp.bottom).offset(ScaleWidth(at: 0))
                    }
                }
            }else {
                if tableView.contentOffset.y < 0 {
                    showSearchTextAnimation()
                }
            }
        }else {
            if tableView.contentOffset.y < 0 {
                showSearchTextAnimation()
            }
        }
    }
    
    private func showSearchTextAnimation(){
        
        DispatchQueue.main.async {[weak self] in
            guard let self = self else{return}
            UIView.animate(withDuration: 0.3, delay: 0.0,
                           usingSpringWithDamping: 1.0, initialSpringVelocity: 5.0,
                           animations: {
                            self.searchTextField.snp.updateConstraints{item in
                                item.top.equalTo(ScaleWidth(at: 8))
                                item.height.equalTo(ScaleWidth(at: 40))
                            }
                            self.searchTextField.isHidden = false
                            self.view.layoutIfNeeded()
            },
                           completion: nil
            )
            self.tableView.snp.updateConstraints {
                $0.top.equalTo(self.searchTextField.snp.bottom).offset(ScaleWidth(at: 8))
            }
        }
    }
    
    func textFieldDidChange(text: String) {
        otpValueFilterDicArray = otpValueDicArray.filter { word in
            return word.account.description.lowercased().contains(text.lowercased()) ||
                word.issuer.description.lowercased().contains(text.lowercased())
        }
        if text == "" {
            otpValueFilterDicArray = otpValueDicArray
        }
        tableView.reloadData()
    }
 
    func textFieldDidBeginEditing(_ textField: UITextField) {
          
        setupViewInSearchStatus()
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
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setNavigate()
    }
    
    func setNavigate() {
        let leftbarItem = UIBarButtonItem(image: .noSmsBack, style: .plain, target: nil, action: nil)
        
        leftbarItem.rx.tap.subscribe(onNext: {[weak self] in
            
            self?.navigationController?.popViewController(animated: true)
        }).disposed(by: disposeBag)
        
        navigationItem.leftBarButtonItem = leftbarItem
        var color: UIColor
        if #available(iOS 13.0, *) {
            
            if UITraitCollection.current.userInterfaceStyle == .some(.dark) {
                
                color = .clear
            } else {
                
                color = .navColorLight
            }
        } else {
            color = .navColorLight
            // Fallback on earlier versions
        }
        navigationController?.navigationBar.barTintColor = color
    }
    
    private func cleanTextField() {
        searchTextField.text = ""
        textFieldDidChange(text: "")
    }
    
    
    // return the number of cells each section.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return otpValueFilterDicArray.count
    }
    
    // return cells
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ShareOTPRecordDetailTableViewCell
        let otpAccount = otpValueFilterDicArray[indexPath.row]
        cell.account.text = "[\(otpAccount.issuer)] \(otpAccount.account)"
        cell.group.text = "分组：\(otpAccount.group)"
        cell.backgroundColor = .otpShareReceiveButtonColor
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    
}

class ShareOTPRecordDetailTableViewCell: UITableViewCell {
        
    var account: UILabel = {
        let label = UILabel()
        label.text = ""
        label.backgroundColor = .clear
        label.setFont(.pingFangMediumFont(size: 16))
            .setTextColor(.otpScanHintTextColor)
            .setNumberOfLine(0)
            .setTextAlignment(.left)
        return label
    }()
    
    var group: UILabel = {
        let label = UILabel()
        label.backgroundColor = .clear
        label.setFont(.pingFangMediumFont(size: 12))
            .setTextColor(.getColor(red: 136, green: 136, blue: 136, alpha: 1))
            .setNumberOfLine(0)
            .setTextAlignment(.left)
        return label
    }()
    
    var lineView: UIView = {
        let view = UIView()
        view.backgroundColor = .otpshareRecordCellLineColor
        return view
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = .clear
        contentView.addSubview(account)
        contentView.addSubview(group)
        contentView.addSubview(lineView)
        account.snp.makeConstraints {
            $0.height.equalTo(22.5)
            $0.left.equalToSuperview().offset(16)
            $0.right.equalToSuperview().offset(16)
            $0.top.equalToSuperview().offset(15)
        }
        
        group.snp.makeConstraints {
            $0.height.equalTo(16.5)
            $0.left.equalToSuperview().offset(16)
            $0.right.equalToSuperview().offset(16)
            $0.top.equalTo(account.snp.bottom).offset(11)
        }
        
        lineView.snp.makeConstraints {
            $0.height.equalTo(5)
            $0.left.equalToSuperview()
            $0.right.equalToSuperview()
            $0.bottom.equalToSuperview()
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


