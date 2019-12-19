
import UIKit
import RxCocoa
import RxSwift

enum NoSMSError: Error {
    
    case imageError
    case imageisNotQRCode
}

protocol PhotoChoseVCViewModelProtocol: BaseVCViewModelProtocol {
    
    var choseImage: Observable<UIImage?> { get }
    
    func saveToken() -> Completable
}

class PhotoChoseVCViewModel: BaseVCViewModel, PhotoChoseVCViewModelProtocol {
    
    let choseImage: Observable<UIImage?>
    
    private let tokenStore: TokenStoreProtocol
    
    init(choseImage: Observable<UIImage?>,
         tokenStore: TokenStoreProtocol = KeychainTokenStore.shared) {
        
        self.choseImage = choseImage
        self.tokenStore = tokenStore
        super.init(navigationItem: BaseNavigaitonItem(title: .init(value: "相册选取扫码")), backgroundColor: .clear)
    }
    
    func saveToken() -> Completable {
        
        return Completable.create { completable in
            
            let dispose = self.choseImage.subscribe(onNext: { image in
                
                guard let pickedImage = image,
                        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy:CIDetectorAccuracyHigh]),
                        let ciImage = CIImage(image: pickedImage),
                        let features = detector.features(in: ciImage) as? [CIQRCodeFeature] else {
                    
                            completable(.error(NoSMSError.imageError))
                            return
                }
                
                guard !features.isEmpty else {
                    completable(.error(NoSMSError.imageisNotQRCode))
                    return
                }
                
                let qrCodeLink = features.reduce(""){ $0 + ($1.messageString ?? "")}
                      
                do {
                    try self.tokenStore.addTokenWith(urlString: qrCodeLink)
                    completable(.completed)
                } catch {
                    
                    completable(.error(error))
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
        view.setBackgroundColor(.backCoverColor)
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
        
        let barHeight = self.navigationController?.navigationBar.frame.height ?? 0
        waitLabel.snp.makeConstraints {
            
            $0.top.equalTo(-barHeight)
            $0.left.right.bottom.equalToSuperview()
        }
        viewModel.choseImage.bind(to: choseImageView.rx.image).disposed(by: disposedBag)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            
            self.viewModel.saveToken()
                .subscribe(onCompleted: {
                    
                    self.waitLabel.isHidden = true
                    
                    NoSMSHUD.showToast(title: "识别成功！") {
                        
                        self.dismiss(animated: true, completion: nil)
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
