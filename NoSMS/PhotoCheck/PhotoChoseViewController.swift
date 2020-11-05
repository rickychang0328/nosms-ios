
import UIKit
import RxCocoa
import RxSwift

enum NoSMSError: Error {
    
    case imageError
    case imageisNotQRCode
    case urlError
}

protocol PhotoChoseVCViewModelProtocol: BaseVCViewModelProtocol {
    
    var choseImage: Observable<UIImage?> { get }
    var placeHolderImage: Observable<UIImage?> { get }
    
    func saveToken() -> Observable<PhotoChoseVCViewModel.Event>
}

class PhotoChoseVCViewModel: BaseVCViewModel, PhotoChoseVCViewModelProtocol {
    
    enum Event {
        
        case mulitpleSuccess(message: String)
        case success(message: String)
        case showAlert(title: String, message: String, completionHander: () -> Void)
        case oneButtonAlert(title: String, message: String, completion: (() -> Void)?)
        case replaceAlertAction(message: String, needMoreText: Bool, replaceHandler: () -> Void, newAddHandler: () -> Void)
    }
    
    let choseImage: Observable<UIImage?>
    
    let placeHolderImage: Observable<UIImage?>
    
    private let tokenStore: TokenStoreProtocol
    
    init(choseImage: Observable<UIImage?>,
         placeHolderImage: Observable<UIImage?>,
         tokenStore: TokenStoreProtocol = KeychainTokenStore.shared) {
        
        self.choseImage = choseImage
        self.tokenStore = tokenStore
        self.placeHolderImage = placeHolderImage
        super.init(navigationItem: BaseNavigaitonItem(title: .init(value: "相册选取")), backgroundColor: .white)
    }
    
    func saveToken() -> Observable<Event> {
        
        return Observable<Event>.create { anyObserver in
            
            let dispose = self.choseImage.subscribe(onNext: { image in
                
                var displayImage = image
                for index in 0...2 {

                    guard let pickedImage = displayImage,
                           let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy:CIDetectorAccuracyHigh]),
                           let ciImage = CIImage(image: pickedImage),
                           let features = detector.features(in: ciImage) as? [CIQRCodeFeature] else {
                                
                        anyObserver.onError(NoSMSError.imageError)
                        return
                    }
                    
                    guard !features.isEmpty else {
                            
                        
                        if index == 1 {
                           
                            displayImage = displayImage?.imageResize(sizeChange: .init(width: 500, height: 500))
                            continue
                        } else if index == 0 {
                            
                            displayImage = displayImage?.imageResize(sizeChange: .init(width: 5000, height: 5000))
                            continue
                        } else {
                               
                            anyObserver.onError(NoSMSError.imageisNotQRCode)
                            return
                        }
                    }
                                   
                    let qrCodeLink = features.reduce(""){ $0 + ($1.messageString ?? "")}
                    
                    if qrCodeLink.mustAuth.getActionEnum() == .some(.mulitpleShare), let urls = try? qrCodeLink.mustAuth.parsingMulitple().urlStrings {
                        
                        self.tokenStore.mulitpleShareURLAction(urlString: urls, eventHandler: { event in
                            
                            switch event {
                            
                            case .success(toast: let toast):
                                anyObserver.onNext(.mulitpleSuccess(message: toast))
                                anyObserver.onCompleted()
                            case .haveSameToken(message: let message, needMoreText: let needMoreText, replaceHandler: let replaceHandler, newAddHandler: let newAddHandler):
                                anyObserver.onNext(.replaceAlertAction(message: message, needMoreText: needMoreText, replaceHandler: replaceHandler, newAddHandler: newAddHandler))
                            case .error(error: let error):
                                anyObserver.onError(error)
                            case .addSuccessButGroupIsMax(title: let title, message: let message):
                                anyObserver.onNext(.oneButtonAlert(title: title, message: message, completion: nil))
                                anyObserver.onCompleted()
                            }
                        })
                        
                    } else {
                        
                        self.tokenStore.addTokenWith(urlString: qrCodeLink) { [weak self] (event) in
                            
                            guard let _ = self else { return }
                            switch event {
                            
                            case .addSuccess:
                                
                                anyObserver.onNext(.success(message: "识别成功！"))
                                anyObserver.onCompleted()
                            case .haveTheSame(let title, let message, let completion):
                                
                                anyObserver.onNext(.showAlert(title: title, message: message, completionHander: completion))
                            case .addError(let error):
                                
                                anyObserver.onError(error)
                            }
                        }
                    }
                    break
                }
            })
            
            return Disposables.create { dispose.dispose() }
        }
    }
}

class PhotoChoseViewController<ViewModel: PhotoChoseVCViewModelProtocol>: BaseViewController<ViewModel> {
    
    private let choseImageView: UIImageView = {
        
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    private let coverView: UIView = {
       
        let view = UIView()
        view.setBackgroundColor(.photoChoseCoverColor)
        return view
    }()
    
    private let waitLabel: UILabel = {
       
        let label = UILabel()
        label.setFont(.pingFangMediumFont(size: 16))
            .setText("正在识别中…")
            .setTextColor(.white)
            .setTextAlignment(.center)
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(choseImageView)
        view.addSubview(coverView)
        view.addSubview(waitLabel)
        
        let leftbarItem = UIBarButtonItem(image: .noSmsBack, style: .plain, target: nil, action: nil)
        navigationItem.leftBarButtonItem = leftbarItem
        
        choseImageView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        coverView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        
        view.layoutIfNeeded()
        let barHeight = (self.navigationController?.navigationBar.frame.height ?? 0) + (self.navigationController?.navigationBar.frame.origin.y ?? 0)
        
        waitLabel.snp.makeConstraints {
            
            $0.top.equalTo(-barHeight)
            $0.left.right.bottom.equalToSuperview()
        }
        
        viewModel.placeHolderImage.bind(to: choseImageView.rx.image).disposed(by: disposedBag)
        viewModel.choseImage.bind(to: choseImageView.rx.image).disposed(by: disposedBag)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            
            self.viewModel.saveToken()
                .subscribe(onNext: { [weak self] event in
                    guard let self = self else { return }
                    self.waitLabel.isHidden = true
                    
                    switch event {
                    
                    case .mulitpleSuccess(message: let message):
                        
                        let vc = self.presentingViewController
                        self.dismiss(animated: true, completion: {
                            
                            NoSMSHUD.showToast(title: message, contentView: vc?.view)
                        })
                        
                    case .success:
                        NoSMSHUD.showToast(title: "识别成功！") {
                            
                            self.dismiss(animated: true, completion: nil)
                        }
                    case .showAlert(let title, let message, let completionHander):
                        
                        self.showAlert(title: title, message: message, confirmTitle: "确认", cancelTitle: "取消", confirmAction: completionHander) {
                            self.navigationController?.popViewController(animated: true)
                        }
                        
                    case .oneButtonAlert(title: let title, message: let message, completion: _ ):
                        
                        self.showNewOneButtonAlert(title: title, message: message) {
                            self.dismiss(animated: true, completion: nil)
                        }
                    case .replaceAlertAction(message: let message, needMoreText: let needMoreText, replaceHandler: let replaceHandler, newAddHandler: let newAddHandler):
                        
                        self.showReplaceAlert(message: message, needMoreText: needMoreText, confirmAction: newAddHandler, replaceAction: replaceHandler, cancelAction: { [weak self] in
                            guard let self = self else { return }
                            self.navigationController?.popViewController(animated: true)
                        })
                    }
                    
                }, onError: { _ in
                    
                    self.waitLabel.isHidden = true
                    NoSMSHUD.showToast(title: "未识别出有效图片，请重新选取") {
                        
                        self.navigationController?.popViewController(animated: true)
                    }
                }).disposed(by: self.disposedBag)
        }
    }
}
