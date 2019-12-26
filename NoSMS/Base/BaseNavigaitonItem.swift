
import Foundation
import RxCocoa
import RxSwift

protocol BaseNavigaitonItemProtocol {
    
    var title: BehaviorSubject<String> { get }
}

struct BaseNavigaitonItem: BaseNavigaitonItemProtocol {
    
    let title: BehaviorSubject<String>
}
