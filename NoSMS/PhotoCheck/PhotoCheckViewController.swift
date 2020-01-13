
import UIKit
import RxCocoa
import RxSwift
import PhotosUI

protocol PhotoCheckVCViewModelProtocol: BaseTableViewVCViewModelProtocol {
    
    var reloadAlbum: PublishSubject<Any> { get }
    var photosCount: Int { get }
    var photoImageData: [PhotoCheckCollectionViewCellViewModelProtocol] { get }
    var newBarViewTitle: BehaviorSubject<String?> { get }
    
    func selectAlbum(index: Int)
    func getAlbum()
    func getImageData(index: Int) -> Observable<UIImage?>
}

class PhotoObject {
        
    let photoAsset: PHAsset
    
    let photoImage: BehaviorSubject<UIImage?>
    
    internal init(photoAsset: PHAsset, photoImage: BehaviorSubject<UIImage?>) {
        self.photoAsset = photoAsset
        self.photoImage = photoImage
    }
    
    func image(targetSize: CGSize) -> Observable<UIImage?> {
        
        if let image = try? photoImage.value(), image.size == targetSize {
            
            return Observable<UIImage?>.create { anyObserver in
                
                anyObserver.onNext(image)
                anyObserver.onCompleted()
                return Disposables.create {}
            }
        } else {
            
            return Observable<UIImage?>.create { anyObserver -> Disposable in
                
                PHCachingImageManager.default().requestImage(for: self.photoAsset, targetSize: targetSize, contentMode: .default, options: nil, resultHandler: { (image, info) in
                    self.photoImage.onNext(image)
                    anyObserver.onNext(image)
                })
                
                return Disposables.create { }
            }
        }
    }

}

class PhotoListObject {
    
    let photoAlbum: PHAssetCollection
    
    var photoObjects: [PhotoObject]
    
    internal init(photoAlbum: PHAssetCollection, photoObjects: [PhotoObject]) {
        self.photoAlbum = photoAlbum
        self.photoObjects = photoObjects
    }
}

class PhotoManager {
    
    static let shared: PhotoManager = .init()
        
    private(set) var photos: [PhotoListObject] = []
    
    private let phImageManager: PHImageManager = .default()
    
    private let phPhoteLibrary: PHPhotoLibrary = .shared()
    
    private let queue: DispatchQueue = .init(label: "Photo")
            
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
            
            var photoObjects: [PhotoObject] = []
            
            if assetFetchResult.count > 0 {
                
                for index in 0 ..< assetFetchResult.count {

                    let behaviorSubject: BehaviorSubject<UIImage?> = .init(value: nil)
                    let asset = assetFetchResult[index]
                    
                    photoObjects.append(PhotoObject(photoAsset: asset, photoImage: behaviorSubject))
                }
                
                // 照片大於零才加入相簿的邏輯 新加照片會讀取的邏輯
                if let sameAlbum = self.photos.first(where: {$0.photoAlbum.localIdentifier == imageList.localIdentifier}),
                    let whereIndex = photoObjects.firstIndex(where: {$0.photoAsset.localIdentifier == sameAlbum.photoObjects[0].photoAsset.localIdentifier}) {
                    
                    for index in 0 ..< whereIndex {
                        
                        sameAlbum.photoObjects.insert(photoObjects[index], at: index)
                    }
                } else {
                    
                    self.photos.append(PhotoListObject(photoAlbum: imageList, photoObjects: photoObjects))
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

class PhotoCheckVCTableViewSectionItems: BaseTableViewSectionItemsProtocol {
    
    let sectionHeaderViewModel: BaseTableViewSectionHeaderFooterViewModelProtocol? = nil
    
    let sectionFooterViewModel: BaseTableViewSectionHeaderFooterViewModelProtocol? = nil
    
    var numberOfRow: Int {
        
        return rowItems.count
    }
    
    subscript(index: Int) -> BaseTableViewCellViewModelProtocol {
        
        rowItems[index]
    }
    
    var rowItems: [PhotoCheckTableViewCellViewModel] = []
}

class PhotoCheckVCViewModel: BaseVCViewModel, PhotoCheckVCViewModelProtocol {
    
    let newBarViewTitle: BehaviorSubject<String?> = .init(value: "")

    var cellViewModels: [BaseTableViewSectionItemsProtocol] {
        
        return [tableViewSectionItem]
    }
    
    private let tableViewSectionItem = PhotoCheckVCTableViewSectionItems()
    
    var tableViewStyle: UITableView.Style { return .grouped }
    
    private let photoManager: PhotoManager = .shared
    
    var photosCount: Int {
        
        return photoImageData.count
    }
    
    private var selectAlbum: Int = 0
    
    var photoImageData: [PhotoCheckCollectionViewCellViewModelProtocol] = []
    let reloadAlbum: PublishSubject<Any> = .init()
    
    init(backgroundColor: UIColor = .clear,
         navigationItem: BaseNavigaitonItemProtocol = BaseNavigaitonItem(title: .init(value: ""))) {
        
        super.init(navigationItem: navigationItem, backgroundColor: backgroundColor)
    }
    
    private func reloadPhoto() {
        
        if selectAlbum < photoManager.photos.count {
            
            photoImageData = photoManager.photos[selectAlbum].photoObjects
                .map({ PhotoCheckCollectionViewCellViewModel(photoObject: $0)})
        }
        reloadAlbum.onNext("")
    }
    
    func selectAlbum(index: Int) {
        
        if index < 0 {
            
            selectAlbum = 0
            return
        }
        
        if photoManager.photos.count == 0 {
            
            return
        }
        selectAlbum = index
        
        for isSeleted in tableViewSectionItem.rowItems {
            
            isSeleted.isSelected.onNext(false)
        }
        
        tableViewSectionItem.rowItems[index].isSelected.onNext(true)
        newBarViewTitle.onNext(photoManager.photos[index].photoAlbum.localizedTitle)
        
        reloadPhoto()
    }
    
    func getAlbum() {
        
        photoManager.reloadAlbum()

        for index in photoManager.photos.indices {
            
            let photoListObject = photoManager.photos[index]
            
            let title = photoListObject.photoAlbum.localizedTitle
            let photoObject = photoListObject.photoObjects[0]
            let photoCount = "(\(photoListObject.photoObjects.count))"
            let isSelected: Bool = false
            
            tableViewSectionItem.rowItems
                .append(PhotoCheckTableViewCellViewModel(photoObject: photoObject,
                                                         title: .init(value: title),
                                                         photoCount: .init(value: photoCount),
                                                         isSelected: .init(value: isSelected)))
        }
        
        selectAlbum(index: selectAlbum)
    }
    
    func getImageData(index: Int) -> Observable<UIImage?> {
        
        let selectAlbum = self.selectAlbum
        
        return Observable<UIImage?>.create { anyObserver -> Disposable in
            
            let asset = self.photoManager.photos[selectAlbum].photoObjects[index].photoAsset
            
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isSynchronous = false

            PHImageManager.default().requestImage(for: asset, targetSize: .init(width: 1000, height: 1000), contentMode: .default, options: options) { image, info in
                
                let imageQualityState = info?[PHImageResultIsDegradedKey] as? Bool
                
                if imageQualityState ?? true {
                    
                    
                } else {
                    
                    anyObserver.onNext(image)
                    anyObserver.onCompleted()
                }
            }
            
            return Disposables.create {}
        }
    }
}

class PhotoCheckViewController<ViewModel: PhotoCheckVCViewModelProtocol>: BaseTableViewController<ViewModel>, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    private let collectionView: UICollectionView = {
       
        let edgeLayout: CGFloat = 3
        let itemWidth = (UIScreen.main.bounds.width - (edgeLayout * 5)) / 4
        let collectionViewFlowLayout = UICollectionViewFlowLayout()
        collectionViewFlowLayout.sectionInset = .init(top: edgeLayout, left: edgeLayout, bottom: edgeLayout, right: edgeLayout)
        collectionViewFlowLayout.minimumLineSpacing = edgeLayout
        collectionViewFlowLayout.minimumInteritemSpacing = edgeLayout
        collectionViewFlowLayout.scrollDirection = .vertical
        collectionViewFlowLayout.itemSize = CGSize(width: itemWidth, height: itemWidth)
        let collectionView: UICollectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionViewFlowLayout)
        return collectionView
    }()
    
    private let navigationBarView: UIView = {
       
        let view = UIView()
        view.setBackgroundColor(.countColor)
        return view
    }()
    
    private let navigationNewTitle: UILabel = {
        
        let label = UILabel()
        label.setFont(.pingFangMediumFont(size: 16))
            .setTextColor(.white)
        return label
    }()
    
    private let tableViewButtonInNavigationBar: UIButton =  {
       
        let button = UIButton()
        button.setImage(.noSmsdown, for: .normal)
        button.setImage(.noSmsUp, for: .selected)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(PhotoCheckCollectionViewCell.self, forCellWithReuseIdentifier: "PhotoCheckCollectionViewCell.self")
        collectionView.backgroundColor = .backgroudColor
        view.addSubview(collectionView)
        view.sendSubviewToBack(collectionView)
        collectionView.snp.makeConstraints {
            
            $0.edges.equalToSuperview()
        }
        collectionView.rx.itemSelected.map{$0.row}
            .subscribe(onNext: { [weak self] index in
                guard let self = self else { return }
                let image = self.viewModel.getImageData(index: index)
                let placeHolderImage = self.viewModel.photoImageData[index].imageData
                self.goPhotoChoseImageVC(image: image, placeHolderImage: placeHolderImage)

            })
            .disposed(by: disposedBag)
        
        tableView.isHidden = true
        tableView.bounces = false
        tableView.backgroundColor = .backCoverColor
        tableView.rx.itemSelected.map({$0.row}).subscribe(onNext: { [weak self] index in
            
            self?.viewModel.selectAlbum(index: index)
            }).disposed(by: disposedBag)
        
        
        viewModel.reloadAlbum.subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.collectionView.reloadData()
            self.resetAlbumSelectView()
            }).disposed(by: disposedBag)
        viewModel.newBarViewTitle.bind(to: navigationNewTitle.rx.text).disposed(by: disposedBag)

        let leftBarButton = UIBarButtonItem(title: "取消", style: .plain, target: nil, action: nil)
        leftBarButton.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.pingFangMediumFont(size: 16)], for: .normal)
        leftBarButton.rx.tap.subscribe(onNext: { [weak self] _ in
            
            self?.dismiss(animated: true, completion: nil)
        }).disposed(by: disposedBag)
        navigationItem.leftBarButtonItem = leftBarButton
        
        navigationBarView.addSubview(navigationNewTitle)
        navigationBarView.addSubview(tableViewButtonInNavigationBar)
        navigationNewTitle.snp.makeConstraints {
            
            $0.left.centerY.equalToSuperview()
        }
        if let navigationBar = self.navigationController?.navigationBar {
                          
           navigationBar.addSubview(navigationBarView)
           navigationBarView.addSubview(tableViewButtonInNavigationBar)
           navigationBarView.snp.makeConstraints {
               
               $0.centerX.equalToSuperview()
               $0.top.bottom.equalToSuperview()
               $0.left.equalTo(ScaleWidth(at: 40)).priorityLow()
               $0.right.equalTo(ScaleWidth(at: -40)).priorityLow()
           }
        }
        tableViewButtonInNavigationBar.snp.makeConstraints {
            
            $0.right.centerY.equalToSuperview()
            $0.width.height.equalTo(navigationNewTitle.snp.height)
            $0.left.equalTo(navigationNewTitle.snp.right).offset(5)
        }

        tableViewButtonInNavigationBar.rx.tap.subscribe(onNext: { [weak self] _ in
            
            guard let self = self else { return }
            
            self.tableViewButtonInNavigationBar.isSelected = !self.tableViewButtonInNavigationBar.isSelected
            self.tableView.isHidden = !self.tableViewButtonInNavigationBar.isSelected
    
        }).disposed(by: disposedBag)
    }
    
    private func resetAlbumSelectView() {
        
        tableViewButtonInNavigationBar.isSelected = false
        tableView.isHidden = true
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationBarView.isHidden = false
        viewModel.getAlbum()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationBarView.isHidden = true
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return viewModel.photosCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCheckCollectionViewCell.self", for: indexPath) as? PhotoCheckCollectionViewCell else {
            
            return UICollectionViewCell()
        }
        
        cell.setupCell(viewModel: viewModel.photoImageData[indexPath.row])
        return cell
    }
    
    private func goPhotoChoseImageVC(image: Observable<UIImage?>, placeHolderImage: Observable<UIImage?>) {
        
        let nextVC = PhotoChoseViewController(viewModel: PhotoChoseVCViewModel(choseImage: image, placeHolderImage: placeHolderImage))
        navigationController?.pushViewController(nextVC, animated: true)
    }
}
