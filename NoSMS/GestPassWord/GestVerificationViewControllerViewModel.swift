

import JXPatternLock
import RxSwift

extension CALayer {
    
    func shakeBody() {
        let keyFrameAnimation = CAKeyframeAnimation(keyPath: "transform.translation.x")
        keyFrameAnimation.values = [0, 16, -16, 8, -8 ,0]
        keyFrameAnimation.duration = 0.3
        keyFrameAnimation.repeatCount = 1
        add(keyFrameAnimation, forKey: "shake")
    }
}

enum GestVerificationViewControllerViewModelEvent {
    
    case verifySuccess
}

protocol GestVerificationViewControllerViewModelType: BaseVCViewModelProtocol {
    
    var titleColor: Observable<UIColor> { get }
    var title: Observable<String> { get }
    
    func didConnectGrid(lockGrid: PatternLockGrid)
    func shouldShowErrorBeforeConnectCompleted() -> Bool
    func didConnectCompleted()
}

class GestVerificationViewControllerViewModel: BaseVCViewModel  ,GestVerificationViewControllerViewModelType {
    
    func didConnectCompleted() {
        
        if currentPassword.count < gestVerificationManager.gestMinLimitCount {
            
            let errorString = gestVerificationManager.gestCountErrorString
            titleBehavior.onNext(errorString)
            titleColorBehavior.onNext(.errorColor)
            currentPassword = .init()
        } else if !isSamePassword {
            
            let errorString = "与原手势不一致，请重新绘制"
            titleBehavior.onNext(errorString)
            titleColorBehavior.onNext(.errorColor)
            currentPassword = .init()
        } else {
            
            cooridator(.verifySuccess)
        }
    }
    
    var isSamePassword: Bool {
        
        return (currentPassword == gestVerificationManager.currentPassword)
    }
    
    func didConnectGrid(lockGrid: PatternLockGrid) {

        currentPassword += lockGrid.identifier
    }
    
    func shouldShowErrorBeforeConnectCompleted() -> Bool {
        
        if isSamePassword {
            
            return false
        } else {
            
            return true
        }
    }
    
    private var currentPassword: String = .init()
    
    private let gestVerificationManager: GestVerificationManager.Type = GestVerificationManager.self
    
    var titleColor: Observable<UIColor> {
        
        return titleColorBehavior.asObservable()
    }
    
    private let titleColorBehavior: BehaviorSubject<UIColor>
    
    var title: Observable<String> {
        
        return titleBehavior.asObservable()
    }
    
    private let titleBehavior: BehaviorSubject<String>
    
    var event: Observable<GestVerificationViewControllerViewModelEvent> {
        
        return eventBehavior.asObservable()
    }
    
    private let eventBehavior: PublishSubject<GestVerificationViewControllerViewModelEvent> = .init()
    
    private let cooridator: (GestVerificationViewControllerViewModelEvent) -> Void
    init(cooridator: @escaping (GestVerificationViewControllerViewModelEvent) -> Void) {
        
        self.cooridator = cooridator
        self.titleBehavior = .init(value: "绘制手势密码")
        self.titleColorBehavior = .init(value: .normalTitleColor)
        super.init(navigationItem: BaseNavigaitonItem(title: .init(value: "验证手势密码")), backgroundColor: .gestVerificationBackgroundColor)
    }
}
