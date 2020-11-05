
import Foundation
import PhotosUI
import AVKit
import RxSwift
import RxCocoa


enum AuthorizationManager {
    
    static func photoLiabraryStatus() -> Driver<PHAuthorizationStatus> {
        
        return Observable<PHAuthorizationStatus>.create { (anyObserver) -> Disposable in
            
            if #available(iOS 14, *) {
                let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
                
                anyObserver.onNext(status)
                anyObserver.onCompleted()
            } else {
                PHPhotoLibrary.requestAuthorization { (status) in
                    
                    anyObserver.onNext(status)
                    anyObserver.onCompleted()
                }
            }
            
            return Disposables.create {}
        }.asDriver(onErrorJustReturn: .denied)
    }
    
    static func cameraStatus() -> AVAuthorizationStatus {
        
        return AVCaptureDevice.authorizationStatus(for: .video)
    }
}
