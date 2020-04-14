
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
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setupNavColor()
    }
    
    private func setupNavColor() {
        
        let color: UIColor
            
        if #available(iOS 13.0, *) {
            
            if UITraitCollection.current.userInterfaceStyle == .some(.dark) {
                    
                color = .navColorDark
            } else {
                    
                color = .navColorLight
            }
        } else {
            color = .navColorLight
                // Fallback on earlier versions
        }
        
        navigationController?.navigationBar.barTintColor = color
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.tintColor = .white
        setupNavColor()
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


class BaseViewControllerNoGeneric: UIViewController {
    
    private let baseVCViewModel: BaseVCViewModelProtocol
    
    var disposedBag: DisposeBag = .init()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        
        return .lightContent
    }
    
    init(baseVCViewModel: BaseVCViewModelProtocol) {
        
        self.baseVCViewModel = baseVCViewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setupNavColor()
    }
    
    private func setupNavColor() {
        
        let color: UIColor
            
        if #available(iOS 13.0, *) {
            
            if UITraitCollection.current.userInterfaceStyle == .some(.dark) {
                    
                color = .navColorDark
            } else {
                    
                color = .navColorLight
            }
        } else {
            color = .navColorLight
                // Fallback on earlier versions
        }
        navigationController?.navigationBar.barTintColor = color
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.tintColor = .white
        setupNavColor()
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.isTranslucent = false

        baseVCViewModel.navigationItemViewModel.title
            .bind(to: navigationItem.rx.title)
            .disposed(by: disposedBag)
        
        baseVCViewModel.vcBackgroundColor
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
