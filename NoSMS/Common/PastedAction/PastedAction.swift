
import Foundation
import RxCocoa
import RxSwift

class PastedAction {
    
    static let shared: PastedAction = PastedAction()
    
    let intoAppPastedAction: PublishSubject<String> = .init()
    
    private init() {}
    
    func applicationDidBecomeActive() {
        
        guard let pastedString = UIPasteboard.general.string?.trimmingCharacters(in: .whitespaces) else {
            
            return
        }
        
        if let _ = try? pastedString.totp.urlStringParsing() {
            
            
        } else {
            
            UserDefaults.standard.setString(key: .pastedString, value: pastedString)
            return
        }
        
        if let beforeString = UserDefaults.standard.getString(key: .pastedString),
            beforeString == pastedString {
            
            
            
        } else {
            
            UserDefaults.standard.setString(key: .pastedString, value: pastedString)
            intoAppPastedAction.onNext(pastedString)
        }
    }
}
