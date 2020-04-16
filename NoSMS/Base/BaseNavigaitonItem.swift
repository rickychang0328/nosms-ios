
import Foundation
import RxCocoa
import RxSwift

protocol BaseNavigaitonItemProtocol {
    
    var title: BehaviorSubject<String> { get }
}

struct BaseNavigaitonItem: BaseNavigaitonItemProtocol {
    
    let title: BehaviorSubject<String>
}

class BaseNavigationController: UINavigationController {
    
    private let blurVC: BlurViewController = BlurViewController()
    
    private let disposedBag: DisposeBag = .init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addChild(blurVC)
        NotificationCenter.default
            .rx.notification(UIApplication.willResignActiveNotification)
            .subscribe(onNext: { [weak self] _ in
                
                if !AuthIDStatusManager.isLockWindow, AuthIDStatusManager.isAuthOpen {
                    
                    self?.showBlurVC()
                }
                
            }).disposed(by: disposedBag)
        
        NotificationCenter.default.rx
            .notification(UIApplication.didBecomeActiveNotification).subscribe(onNext: { [weak self] _ in
                
                if self?.blurVC.view.superview != nil {
                    
                    self?.dismissBlur()
                }
            }).disposed(by: disposedBag)
    }
    
    private func showBlurVC() {
        blurVC.reset()
        view.addSubview(blurVC.view)
        blurVC.view.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    private func dismissBlur() {
        
        blurVC.view.removeFromSuperview()
    }
}
