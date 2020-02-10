
import UIKit
import RxSwift
import RxCocoa
import WebKit

protocol BaseWebVCViewModelProtocol: BaseVCViewModelProtocol {
    
    var urlRequest: URLRequest { get }
}

class BaseWebViewController<ViewModel: BaseWebVCViewModelProtocol>: BaseViewController<ViewModel>, WKNavigationDelegate {
    
    private lazy var webView: WKWebView = {
        
        let view = WKWebView()
        view.load(viewModel.urlRequest)
        view.navigationDelegate = self
        return view
    }()
    
    private let loadingIndicator: UIActivityIndicatorView = {
        
        let view = UIActivityIndicatorView()
        view.color = .red
        view.style = .whiteLarge
        return view
    }()
    
    private let reloadButton: UIButton = {
       
        let button = UIButton()
        button.setTitle("loading", for: .normal)
        button.setTitleColor(.red, for: .normal)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(webView)
        view.addSubview(loadingIndicator)
        view.addSubview(reloadButton)
        
        webView.snp.makeConstraints {
            
            $0.edges.equalToSuperview()
        }
        
        loadingIndicator.snp.makeConstraints {
            
            $0.center.equalToSuperview()
            $0.width.height.equalTo(100)
        }
        
        reloadButton.snp.makeConstraints {
            
            $0.center.equalToSuperview()
            $0.width.height.equalTo(150)
        }
        
        reloadButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.webView.load(self.viewModel.urlRequest)
            }).disposed(by: disposedBag)
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        
        loadingIndicator.startAnimating()
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            
            self.loadingIndicator.stopAnimating()

        }
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                   
            self.loadingIndicator.stopAnimating()
        }
    }
}



class PrivacyVCViewModel: BaseWebVCViewModelProtocol {
    
    private(set) lazy var urlRequest: URLRequest = .init(url: url)
    
    private let url: URL = (URL(string: "https://mustauth.com/privacy.html") ?? URL(fileReferenceLiteralResourceName: ""))
    
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
    
    private(set) lazy var urlRequest: URLRequest = .init(url: url)

    private let url: URL = (URL(string: "https://mustauth.com/help.html") ?? URL(fileReferenceLiteralResourceName: ""))
    
    let navigationItemViewModel: BaseNavigaitonItemProtocol = BaseNavigaitonItem(title: .init(value: "帮助中心"))
    
    let vcBackgroundColor: BehaviorSubject<UIColor> = .init(value: .clear)
}

class HelperViewController: BaseWebViewController<HelperVCViewModel> {
    
    convenience init() {
        
        let viewModel = HelperVCViewModel()
        self.init(viewModel: viewModel)
    }
}

