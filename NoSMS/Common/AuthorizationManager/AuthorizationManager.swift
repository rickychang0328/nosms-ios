
import Foundation
import PhotosUI
import AVKit
import RxSwift
import RxCocoa


struct AuthorizationManager {
    
    static func photoLiabraryStatus() -> Driver<PHAuthorizationStatus> {
        
        return Observable<PHAuthorizationStatus>.create { (anyObserver) -> Disposable in
            
            PHPhotoLibrary.requestAuthorization { (status) in
                
                anyObserver.onNext(status)
                anyObserver.onCompleted()
            }
            return Disposables.create {}
        }.asDriver(onErrorJustReturn: .denied)
    }
    
    static func cameraStatus() -> AVAuthorizationStatus {
        
        return AVCaptureDevice.authorizationStatus(for: .video)
    }
}
