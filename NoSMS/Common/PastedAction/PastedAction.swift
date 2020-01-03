
import Foundation
import RxCocoa
import RxSwift

class PastedAction {
    
    static let shared: PastedAction = PastedAction()
    
    let intoAppPastedAction: PublishSubject<String> = .init()
    
    private var openFromURL: Bool = false
    
    private init() {}
    
    func applicationIsOpenFromURL() {
        
        openFromURL = true
    }
    
    func applicationDidBecomeActive() {
        
        if openFromURL {
            
            openFromURL = false
            return
        }
        
        guard let pastedString = UIPasteboard.general.string?.trimmingCharacters(in: .whitespaces) else {
            
            return
        }
        
        if let token = try? pastedString.mustAuth.parsingSetURL() {
            
            if token.action == .get {
                
                return
            }
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
