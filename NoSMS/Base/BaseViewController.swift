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
    var intoAppPastedAction: PublishSubject<String> { get }
}

extension BaseVCViewModelProtocol {
    
    var intoAppPastedAction: PublishSubject<String> {
        
        return PastedAction.shared.intoAppPastedAction
    }
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
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        
        return .lightContent
    }
    
    init(viewModel: ViewModel) {
        
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.barTintColor = .countColor
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.isTranslucent = false

        viewModel.navigationItemViewModel.title
            .bind(to: navigationItem.rx.title)
            .disposed(by: disposedBag)
        
        viewModel.vcBackgroundColor
            .bind(to: view.rx.backgroundColor)
        .disposed(by: disposedBag)
        
        let leftbarItem = UIBarButtonItem(image: .noSmsBack, style: .plain, target: nil, action: nil)

        leftbarItem.rx.tap.subscribe(onNext: {[weak self] in
            
            self?.navigationController?.popViewController(animated: true)
        }).disposed(by: disposedBag)
        
        navigationItem.leftBarButtonItem = leftbarItem
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("Deinit:\(self)")
    }
}
