
import UIKit
import RxSwift
import RxCocoa
import WebKit

protocol BaseWebVCViewModelProtocol: BaseVCViewModelProtocol {
    
    var url: URL { get }
}

class BaseWebViewController<ViewModel: BaseWebVCViewModelProtocol>: BaseViewController<ViewModel> {
    
    private lazy var webView: WKWebView = {
        
        let view = WKWebView()
        view.load(URLRequest(url: viewModel.url))
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(webView)
        
        webView.snp.makeConstraints {
            
            $0.edges.equalToSuperview()
        }
    }
}

class PrivacyVCViewModel: BaseWebVCViewModelProtocol {
    
    let url: URL = (URL(string: "https://mustauth.com/privacy.html") ?? URL(fileReferenceLiteralResourceName: ""))
    
    let navigationItemViewModel: BaseNavigaitonItemProtocol = BaseNavigaitonItem(title: .init(value: "隐私权政策"))
    
    let vcBackgroundColor: BehaviorSubject<UIColor> = .init(value: .clear)
}

class PrivacyViewController: BaseWebViewController<PrivacyVCViewModel> {
    
    convenience init() {
        
        let viewModel = PrivacyVCViewModel()
        self.init(viewModel: viewModel)
    }
}

class HelperVCViewModel: BaseWebVCViewModelProtocol {
    
    let url: URL = (URL(string: "https://mustauth.com/help.html") ?? URL(fileReferenceLiteralResourceName: ""))
    
    let navigationItemViewModel: BaseNavigaitonItemProtocol = BaseNavigaitonItem(title: .init(value: "帮助中心"))
    
    let vcBackgroundColor: BehaviorSubject<UIColor> = .init(value: .clear)
}

class HelperViewController: BaseWebViewController<HelperVCViewModel> {
    
    convenience init() {
        
        let viewModel = HelperVCViewModel()
        self.init(viewModel: viewModel)
    }
}

