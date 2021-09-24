

import Foundation
import RxSwift

enum GestVerificationManager {
        
    static var isOpen: Bool {
        
        return UserDefaults.standard.bool(forKey: UserDefaults.Key.isGestVerifyOpen.string)
    }
    
    static var isOpenObservable: Observable<Bool> {
        return isOpenBehavior.asObservable()
    }
    
    private static let isOpenBehavior: BehaviorSubject<Bool> = .init(value: isOpen)
    
    static var currentPassword: String? {
        
        if !isOpen {
            
            return nil
        } else {
            
            return UserDefaults.standard.getString(key: .gestVerifyPassWord)
        }
    }
    
    static func closeGest() {
        
        setIsOpen(isOpen: false)
        UserDefaults.standard.setString(key: .gestVerifyPassWord, value: "")
    }
    
    private static func setIsOpen(isOpen: Bool) {
        
        UserDefaults.standard.setValue(isOpen, forKey: UserDefaults.Key.isGestVerifyOpen.string)
        isOpenBehavior.onNext(isOpen)
    }
    
    static func setCurrentPassword(password: String) {
        
        UserDefaults.standard.setString(key: .gestVerifyPassWord, value: password)
        setIsOpen(isOpen: true)
    }
    
    static var gestCountErrorString: String { return "最少需要连接4个点" }
    static var gestMinLimitCount: Int { return 4 }

}
