
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
        view.navigationDelegate = self
        view.isHidden = true
        view.load(viewModel.urlRequest)
        return view
    }()
    
    private let loadingEventImageView: UIImageView = {
        
        let view = UIImageView()
        view.image = UIImage.gif(name: "loading_ps")
        return view
    }()
    
    private let loadingTitleLabel: UILabel = {
        
        let label = UILabel()
        label.setFont(.pingFangMediumFont(size: 15))
            .setTextColor(.webViewTextColor)
            .setTextAlignment(.center)
        return label
    }()
    
    private let reloadButton: UIButton = {
       
        let button = UIButton()
        button.setTitle("重新加载", for: .normal)
        button.isHidden = true
        button.backgroundColor = .clear
        button.addCornerRadius(at: ScaleWidth(at: 6))
            .addBorder(color: .webViewReloadButtonColor, width: ScaleWidth(at: 0.5))
        button.setTitleColor(.webViewReloadButtonColor, for: .normal)
        button.titleLabel?.font = .pingFangMediumFont(size: 15)
        return button
    }()
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setCGColor()
    }
    
    private func setCGColor() {
        
        reloadButton.layer.borderColor = UIColor.webViewReloadButtonColor.cgColor
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .webViewBackgroundColor
        view.addSubview(webView)
        view.addSubview(loadingEventImageView)
        view.addSubview(loadingTitleLabel)
        view.addSubview(reloadButton)
        
        webView.snp.makeConstraints {
            
            $0.edges.equalToSuperview()
        }
        loadingEventImageView.snp.makeConstraints {
            
            $0.top.equalTo(ScaleHeight(at: 186.5))
            $0.centerX.equalToSuperview()
            $0.left.equalTo(ScaleWidth(at: 60))
            $0.right.equalTo(ScaleWidth(at: -60))
            $0.height.equalTo(ScaleWidth(at: 89))
        }
        
        loadingTitleLabel.snp.makeConstraints {
            
            $0.top.equalTo(loadingEventImageView.snp.bottom).offset(ScaleHeight(at: 33.5))
            $0.left.right.centerX.equalToSuperview()
            $0.height.equalTo(ScaleWidth(at: 21))
        }
        
        reloadButton.snp.makeConstraints {
            
            $0.top.equalTo(loadingTitleLabel.snp.bottom).offset(ScaleHeight(at: 25))
            $0.centerX.equalToSuperview()
            $0.width.equalTo(ScaleWidth(at: 140))
            $0.height.equalTo(ScaleWidth(at: 42))
        }
        
        reloadButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.webView.load(self.viewModel.urlRequest)
            }).disposed(by: disposedBag)
    }
    
    private func loadingDone() {
        
        loadingTitleLabel.isHidden = true
        reloadButton.isHidden = true
        loadingEventImageView.isHidden = true
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        
        reloadButton.isHidden = true
        loadingTitleLabel.setText("内容加载中…")
        loadingEventImageView.image = UIImage.gif(name: "loading_ps")
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        loadingDone()
        webView.isHidden = false
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
                    
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            
            self.loadingEventImageView.image = .noSmsNoInternetConnection
            self.loadingTitleLabel.setText("获取网络数据失败")
            self.reloadButton.isHidden = false
        }
    }
    
    deinit {
        
        let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
        let date = Date(timeIntervalSince1970: 0)
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes as! Set<String>, modifiedSince: date, completionHandler:{ })
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

