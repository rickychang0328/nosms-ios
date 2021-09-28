
import Foundation
import RxSwift
import JXPatternLock

enum GestVerificationSettingCooridator {
    
    case settingPasswordDone
}

protocol GestVerificationSettingViewControllerViewModelType: GestVerificationViewControllerViewModelType {
    
    var pathViewGridMatrix: Observable<Matrix> { get }
    var resetButtonIsHidden: Observable<Bool> { get }
    var resetPathViewSignal: Observable<Void> { get }
    func reset()
}

class GestVerificationSettingViewControllerViewModel:
    GestVerificationSettingViewControllerViewModelType {
    
    enum Status {
        
        case firstIn
        case secondConfirm(firstPassWord: String)
        
        var titleString: String {
            
            switch self {
            
            case .firstIn:
                
                return "绘制手势密码"
            case .secondConfirm:
                
                return "再次绘制手势密码"
            }
        }
    }
    
    let navigationItemViewModel: BaseNavigaitonItemProtocol
    
    let vcBackgroundColor: BehaviorSubject<UIColor> = .init(value: .gestVerificationBackgroundColor)

    private let cooridnator: (GestVerificationSettingCooridator) -> ()
    
    private let gestVerificationManager: GestVerificationManager.Type = GestVerificationManager.self
    
    var titleColor: Observable<UIColor> {
        
        return titleColorBehavior.asObservable()
    }
    
    private let titleColorBehavior: BehaviorSubject<UIColor> = .init(value: .normalTitleColor)
    
    var title: Observable<String> {
        
        return titleBehavior.asObservable()
    }
    
    private let titleBehavior: BehaviorSubject<String> = .init(value: Status.firstIn.titleString)
    
    var pathViewGridMatrix: Observable<Matrix> {
        
        return pathViewGridMatrixPublisher.asObservable()
    }
    
    private let pathViewGridMatrixPublisher: PublishSubject<Matrix> = .init()
    
    var resetButtonIsHidden: Observable<Bool> {
        
        return resetButtonIsHiddenBehavior.asObservable()
    }
    
    private let resetButtonIsHiddenBehavior: BehaviorSubject<Bool> = .init(value: true)
    
    var resetPathViewSignal: Observable<Void> {
        
        return resetSignalPublisher.asObservable()
    }
    
    private let resetSignalPublisher: PublishSubject<Void> = .init()
    
    var status: Status = .firstIn
    var currentPassWord: String = .init()
    
    init(navigationTitle: String, cooridnator: @escaping (GestVerificationSettingCooridator) -> ()) {
        self.navigationItemViewModel = BaseNavigaitonItem(title: .init(value: navigationTitle))
        self.cooridnator = cooridnator
    }
    
    func reset() {
        
        status = .firstIn
        titleBehavior.onNext(status.titleString)
        resetButtonIsHiddenBehavior.onNext(true)
        titleColorBehavior.onNext(.normalTitleColor)
        currentPassWord = .init()
        resetSignalPublisher.onNext(())
    }
        
    func didConnectGrid(lockGrid: PatternLockGrid) {
        
        currentPassWord += lockGrid.identifier
        if case Status.firstIn = status {
            
            pathViewGridMatrixPublisher.onNext(lockGrid.matrix)
        }
    }
    
    func shouldShowErrorBeforeConnectCompleted() -> Bool {
        
        if currentPassWord.count < gestVerificationManager.gestMinLimitCount {
            
            return true
        } else if case Status.secondConfirm(firstPassWord: let firstPassword) = status {
            
            return (firstPassword != currentPassWord)
        } else {
            
            return false
        }
    }
    
    func didConnectCompleted() {
        
        guard gestVerificationManager.gestMinLimitCount <= currentPassWord.count else {
            
            titleBehavior.onNext(gestVerificationManager.gestCountErrorString)
            titleColorBehavior.onNext(.errorColor)
            currentPassWord = .init()
            
            if case Status.firstIn = status {
                
                resetSignalPublisher.onNext(())
            }
            return
        }
        switch status {
        
        case .firstIn:
            
            status = .secondConfirm(firstPassWord: currentPassWord)
            titleBehavior.onNext(status.titleString)
            titleColorBehavior.onNext(.normalTitleColor)
            currentPassWord = .init()
            resetButtonIsHiddenBehavior.onNext(false)
        case .secondConfirm(firstPassWord: let lastPassword):
            
            if lastPassword != currentPassWord {
                
                let errorString = "与上次绘制不一致，请重新绘制"
                titleBehavior.onNext(errorString)
                titleColorBehavior.onNext(.errorColor)
                currentPassWord = .init()
            } else {
                
                gestVerificationManager.setCurrentPassword(password: currentPassWord)
                cooridnator(.settingPasswordDone)
            }
        }
    }
}
