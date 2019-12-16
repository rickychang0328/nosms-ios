
import UIKit
import RxCocoa
import RxSwift
import PhotosUI

protocol PhotoCheckVCViewModelProtocol: BaseVCViewModelProtocol {
    
    func saveToken(urlString: String) -> Completable
}

class PhotoCheckVCViewModel: BaseVCViewModel, PhotoCheckVCViewModelProtocol {

    private let tokenStore: TokenStoreProtocol
    
    init(tokenStore: TokenStoreProtocol = KeychainTokenStore.shared,
         backgroundColor: UIColor = .clear,
         navigationItem: BaseNavigaitonItemProtocol = BaseNavigaitonItem(title: .init(value: ""))) {
        
        self.tokenStore = tokenStore
        super.init(navigationItem: navigationItem, backgroundColor: backgroundColor)
    }
    
    func saveToken(urlString: String) -> Completable {
        
        return Completable.create { completable in
            
            do {
                try self.tokenStore.addTokenWith(urlString: urlString)
                completable(.completed)
            } catch {
                
                completable(.error(error))
            }
            
            return Disposables.create {}
        }
    }
}

class PhotoCheckViewController<ViewModel: PhotoCheckVCViewModelProtocol>: BaseViewController<ViewModel>, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let photoController = UIImagePickerController()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
//         photoController = UIImagePickerController()
        photoController.delegate = self
        photoController.sourceType = .photoLibrary
        addChild(photoController)
        view.addSubview(photoController.view)
    }
  
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage,
            let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy:CIDetectorAccuracyHigh]),
            let ciImage = CIImage(image: pickedImage),
            let features = detector.features(in: ciImage) as? [CIQRCodeFeature] else {return}
        
        guard !features.isEmpty else {
            showErrorAlert(title: "照片不符", message: "掃不到QR碼")
            return
        }
        
        let qrCodeLink = features.reduce(""){ $0 + ($1.messageString ?? "")}
        
        viewModel.saveToken(urlString: qrCodeLink)
            .subscribe(onCompleted: { [weak picker] in
                
                picker?.dismiss(animated: true, completion: nil)
                
            }, onError: { error in
                
                print(error)
            }).disposed(by: disposedBag)
    }
}
