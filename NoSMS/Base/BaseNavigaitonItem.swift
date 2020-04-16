
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
    
    private let blurVC: CustomBlurView = .init(frame: .zero)
    private let disposedBag: DisposeBag = .init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default
            .rx.notification(UIApplication.willResignActiveNotification)
            .subscribe(onNext: { [weak self] _ in
                
                if !AuthIDStatusManager.isLockWindow, AuthIDStatusManager.isAuthOpen {
                    
                    self?.showBlurVC()
                }
                
            }).disposed(by: disposedBag)
        
        NotificationCenter.default.rx
            .notification(UIApplication.didBecomeActiveNotification).subscribe(onNext: { [weak self] _ in
                
                if self?.blurVC.superview != nil {
                    
                    self?.dismissBlur()
                }
            }).disposed(by: disposedBag)
    }
    
    private func showBlurVC() {
        
        view.addSubview(blurVC)
        blurVC.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        blurVC.blurView.refresh()
        blurVC.blurView.animate()
    }
    
    private func dismissBlur() {
        
        blurVC.removeFromSuperview()
    }
}
