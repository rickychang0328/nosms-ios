
import PhotosUI
import RxSwift
import RxCocoa


class PhotoObject {
        
    let photoAsset: PHAsset
    
    let photoImage: BehaviorSubject<UIImage?>

    private var isDisplay: Bool = false
 
    internal init(photoAsset: PHAsset, photoImage: BehaviorSubject<UIImage?>) {
        self.photoAsset = photoAsset
        self.photoImage = photoImage
    }
    
    func image(targetSize: CGSize) -> Observable<UIImage?> {
        
        isDisplay = true
        return Observable<UIImage?>.create { anyObserver -> Disposable in
            
            PHImageManager.default().requestImage(for: self.photoAsset, targetSize: targetSize, contentMode: .default, options: nil, resultHandler: { (image, info) in
                
                if self.isDisplay {
                    
                    anyObserver.onNext(image)
                    self.photoImage.onNext(image)
                }
            })
            
            return Disposables.create {
                
                self.isDisplay = false
                self.photoImage.onNext(nil)
            }
        }
    }
}

class PhotoListObject {
    
    let photoAlbum: PHAssetCollection
    
    var photoObjects: [PhotoObject]
    
    var photoFetchAsset: PHFetchResult<PHAsset>
    
    let photoReloadOnceCount: Int
    
    internal init(photoAlbum: PHAssetCollection, photoObjects: [PhotoObject], photoFetchAsset: PHFetchResult<PHAsset>, photoReloadOnceCount: Int) {
        
        self.photoAlbum = photoAlbum
        self.photoObjects = photoObjects
        self.photoFetchAsset = photoFetchAsset
        self.photoReloadOnceCount = photoReloadOnceCount
    }
    
    func getMorePhotoObject() {
        
        let nowCount = photoObjects.count
        
        let allAlbum = photoFetchAsset.count
        
        if nowCount < allAlbum {
            
            let addCount: Int
            
            if (nowCount + photoReloadOnceCount) < allAlbum {
                
                addCount = nowCount + photoReloadOnceCount
            } else {
                
                addCount = allAlbum
            }
            
            for index in nowCount ..< addCount {
                
                let photoAsset = photoFetchAsset[index]
                photoObjects.append(PhotoObject(photoAsset: photoAsset, photoImage: .init(value: nil)))
            }
        } else {
            
            return
        }
    }
}

class PhotoManager {
    
    static let shared: PhotoManager = .init()
        
    private(set) var photos: [PhotoListObject] = []
    
    private let phImageManager: PHImageManager = .default()
    
    private let phPhoteLibrary: PHPhotoLibrary = .shared()
        
    let photoReloadOnceCount = 100
    
    private init() {
        
        reloadAlbum()
    }
    
    func reloadAlbum() {
                
        let smartOptions = PHFetchOptions()
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: smartOptions)
        
        //生成相簿
        for index in 0 ..< smartAlbums.count {
                        
            smartOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            smartOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
            let imageList = smartAlbums[index]
            let assetFetchResult = PHAsset.fetchAssets(in: imageList, options: smartOptions)
                        
            if assetFetchResult.count > 0 {
                // 照片大於零才加入相簿的邏輯 新加照片會讀取的邏輯
                if let sameAlbum = self.photos.first(where: {$0.photoAlbum.localIdentifier == imageList.localIdentifier}) {
                    
                    var photoObjects: [PhotoObject] = []
                    
                    for index in 0 ..< assetFetchResult.count {
                        
                        let asset = assetFetchResult[index]
                        
                        if asset.localIdentifier == sameAlbum.photoObjects[0].photoAsset.localIdentifier {
                            
                            break
                        } else {
                            
                            photoObjects.append(PhotoObject(photoAsset: asset, photoImage: .init(value: nil)))
                        }
                    }
                    sameAlbum.photoFetchAsset = assetFetchResult
                    sameAlbum.photoObjects = photoObjects + sameAlbum.photoObjects
                } else {
                    
                    var photoObjects: [PhotoObject] = []
                    
                    let loopEnd: Int
                    
                    if assetFetchResult.count > photoReloadOnceCount {
                        
                        loopEnd = photoReloadOnceCount
                    } else {
                        
                        loopEnd = assetFetchResult.count
                    }
                    
                    for index in 0 ..< loopEnd {
                        
                        let behaviorSubject: BehaviorSubject<UIImage?> = .init(value: nil)
                        let asset = assetFetchResult[index]
                        photoObjects.append(PhotoObject(photoAsset: asset, photoImage: behaviorSubject))
                    }
                    
                    self.photos.append(PhotoListObject(photoAlbum: imageList, photoObjects: photoObjects, photoFetchAsset: assetFetchResult, photoReloadOnceCount: photoReloadOnceCount))
                }
            }
        }
        
        //將最近加入放置頭位
        guard let recentlyAddedIndex = photos.firstIndex(where: {$0.photoAlbum.assetCollectionSubtype == .smartAlbumRecentlyAdded}) else {
            
            return
        }
        
        let album = photos[recentlyAddedIndex]
        photos.remove(at: recentlyAddedIndex)
        photos.insert(album, at: 0)
    }
}
