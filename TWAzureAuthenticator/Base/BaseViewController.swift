//
//  BaseViewController.swift
//  TWAzureAuthenticator
//
//  Created by 誠帷數位科技 on 2019/11/25.
//

import UIKit
import RxSwift
import RxCocoa

protocol BaseVCViewModelProtocol {
    
    var navigationItemViewModel: BaseNavigaitonItemProtocol { get }
    var vcBackgroundColor: BehaviorSubject<UIColor> { get }
}

class BaseVCViewModel: BaseVCViewModelProtocol {
    
    let vcBackgroundColor: BehaviorSubject<UIColor>

    let navigationItemViewModel: BaseNavigaitonItemProtocol
    
    var disposedBag: DisposeBag = .init()

    init(navigationItem: BaseNavigaitonItemProtocol, backgroundColor: UIColor) {
        
        self.navigationItemViewModel = navigationItem
        self.vcBackgroundColor = .init(value: backgroundColor)
    }
}


class BaseViewController<ViewModel: BaseVCViewModelProtocol>: UIViewController {
    
    let viewModel: ViewModel
    
    var disposedBag: DisposeBag = .init()
    
    init(viewModel: ViewModel) {
        
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.navigationItemViewModel.title
            .bind(to: navigationItem.rx.title)
            .disposed(by: disposedBag)
        
        viewModel.vcBackgroundColor
            .bind(to: view.rx.backgroundColor)
            .disposed(by: disposedBag)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("Deinit:\(self)")
    }
}
