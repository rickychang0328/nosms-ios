//
//  TokenListTableViewCell.swift
//  TWAzureAuthenticator
//
//  Created by 誠帷數位科技 on 2019/11/25.
//

import UIKit
import RxCocoa
import RxSwift

protocol TokenListTableViewCellViewModelProtocol: BaseTableViewCellViewModelProtocol {
    
    var name: Observable<String> { get }
    var password: Observable<String> { get }
    var issuer: Observable<String> { get }
    var lastTime: BehaviorSubject<String> { get }
}

class TokenListTableViewCellViewModel: TokenListTableViewCellViewModelProtocol {
    
    let baseCellItem: BaseTableViewCellViewModelItemProtocol

    let name: Observable<String>
    
    let password: Observable<String>
    
    let issuer: Observable<String>
    
    let lastTime: BehaviorSubject<String>
    
    var cellFactoryType: TableViewCellFactoryType { .tokenList(viewModel: self) }
    
    internal init(baseViewModelItem: BaseTableViewCellViewModelItemProtocol,
                  name: Observable<String>,
                  password: Observable<String>,
                  issuer: Observable<String>,
                  lastTime: BehaviorSubject<String>) {
        
        self.baseCellItem = baseViewModelItem
        self.name = name.map { "Name:" + $0 }
        self.password = password.map { "PassWord:" + $0 }
        self.issuer = issuer.map { "Issuer:" + $0 }
        self.lastTime = lastTime
    }
}
 
class TokenListTableViewCell<ViewModel: TokenListTableViewCellViewModelProtocol>: BaseTableViewCell<ViewModel> {
    
    private let nameLabel: UILabel = {
       
        let label = UILabel()
        return label
    }()
    
    private let passwordLabel: UILabel = {
          
        let label = UILabel()
        label.setFont(.avenirHeavyFont(size: 32))
        return label
    }()
    
    private let issuerLabel: UILabel = {
          
        let label = UILabel()
        return label
    }()
    
    private let lastTimeLabel: UILabel = {
        
        let label = UILabel()
        label.setFont(.avenirHeavyFont(size: 18))
        return label
    }()
    
    private let underLineView: UIView = {
       
        let view = UIView()
        view.setBackgroundColor(.gray)
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
        
        contentView.addSubview(nameLabel)
        contentView.addSubview(passwordLabel)
        contentView.addSubview(issuerLabel)
        contentView.addSubview(underLineView)
        contentView.addSubview(lastTimeLabel)
        
        nameLabel.snp.makeConstraints {
            
            $0.top.left.equalTo(8)
            $0.right.equalTo(-8)
        }
        
        passwordLabel.snp.makeConstraints {
            
            $0.left.right.equalTo(nameLabel)
            $0.top.equalTo(nameLabel.snp.bottom).offset(6)
        }
        
        issuerLabel.snp.makeConstraints {
            
            $0.left.right.equalTo(nameLabel)
            $0.top.equalTo(passwordLabel.snp.bottom).offset(6)
            $0.bottom.equalToSuperview().offset(-6)
        }
        
        underLineView.snp.makeConstraints {
            
            $0.bottom.left.right.equalToSuperview()
            $0.height.equalTo(1)
        }
    
        lastTimeLabel.snp.makeConstraints {
            
            $0.centerY.equalTo(passwordLabel)
            $0.right.equalTo(-8)
        }
    }
    
    override func bindData(viewModel: ViewModel) {
        super.bindData(viewModel: viewModel)
        
        viewModel.name
            .asDriver(onErrorJustReturn: "")
            .drive(nameLabel.rx.text)
            .disposed(by: disposedBag)
        
        viewModel.issuer
            .bind(to: issuerLabel.rx.text)
            .disposed(by: disposedBag)
        
        viewModel.password
            .bind(to: passwordLabel.rx.text)
            .disposed(by: disposedBag)
        
        viewModel.lastTime
            .bind(to: lastTimeLabel.rx.text)
            .disposed(by: disposedBag)
    }
}

