
import UIKit
import RxCocoa
import RxSwift
import PhotosUI

protocol PhotoCheckVCViewModelProtocol: BaseTableViewVCViewModelProtocol {
    
    var reloadAlbum: PublishSubject<PhotoCheckVCViewModel.Event> { get }
    var photosCount: Int { get }
    var photoImageData: [PhotoCheckCollectionViewCellViewModelProtocol] { get }
    var newBarViewTitle: BehaviorSubject<String?> { get }
    
    func selectAlbum(index: Int)
    func getAlbum()
    func getImageData(index: Int) -> Observable<UIImage?>
    func reloadMorePhoto()
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
    
    enum Event {
        
        case selectAlbumDone
        case addPhotoDone
    }
    
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
    let reloadAlbum: PublishSubject<Event> = .init()
    
    init(backgroundColor: UIColor = .clear,
         navigationItem: BaseNavigaitonItemProtocol = BaseNavigaitonItem(title: .init(value: ""))) {
        
        super.init(navigationItem: navigationItem, backgroundColor: backgroundColor)
    }
    
    private func reloadPhoto() {
        
        if selectAlbum < photoManager.photos.count {
            
            photoImageData = photoManager.photos[selectAlbum].photoObjects
                .map({ PhotoCheckCollectionViewCellViewModel(photoObject: $0)})
        }
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
        reloadAlbum.onNext(.selectAlbumDone)
    }
    
    func getAlbum() {
        
        photoManager.reloadAlbum()
        
        tableViewSectionItem.rowItems = []
        for index in photoManager.photos.indices {
            
            let photoListObject = photoManager.photos[index]
            
            let title = photoListObject.photoAlbum.localizedTitle
            let photoObject = photoListObject.photoObjects[0]
            let photoCount = "(\(photoListObject.photoFetchAsset.count))"
            let isSelected: Bool = false
            
            tableViewSectionItem.rowItems
                .append(PhotoCheckTableViewCellViewModel(photoObject: photoObject,
                                                         title: .init(value: title),
                                                         photoCount: .init(value: photoCount),
                                                         isSelected: .init(value: isSelected)))
        }
        
        selectAlbum(index: selectAlbum)
    }
    
    func reloadMorePhoto() {
        
        let nowPhotoList = photoManager.photos[selectAlbum]
        
        if photoImageData.count == nowPhotoList.photoFetchAsset.count {
            
            return
        } else {
            
            if photoImageData.count == nowPhotoList.photoObjects.count {
                
                nowPhotoList.getMorePhotoObject()
                reloadPhoto()
                reloadAlbum.onNext(.addPhotoDone)
            } else {
                
                return
            }
        }
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
        collectionView.rx.itemSelected.map{ $0.row }
            .subscribe(onNext: { [weak self] index in
                guard let self = self else { return }
                let image = self.viewModel.getImageData(index: index)
                let placeHolderImage = self.viewModel.photoImageData[index].imageData
                self.goPhotoChoseImageVC(image: image, placeHolderImage: placeHolderImage)

            })
            .disposed(by: disposedBag)

        collectionView.rx.willDisplayCell.map({$0.at.row})
            .subscribe(onNext: { [weak self] index in

                guard let self = self else { return }
                if index > self.viewModel.photosCount - 20 {

                    self.viewModel.reloadMorePhoto()
                }
            }).disposed(by: disposedBag)
        
        tableView.isHidden = true
        tableView.bounces = false
        tableView.backgroundColor = .backCoverColor
        tableView.rx.itemSelected.map({$0.row})
            .subscribe(onNext: { [weak self] index in
            
                self?.viewModel.selectAlbum(index: index)
            }).disposed(by: disposedBag)
        
        viewModel.reloadAlbum.subscribe(onNext: { [weak self] event in
                guard let self = self else { return }
            
                self.collectionView.reloadData()
                switch event {
                    
                case .selectAlbumDone:
                    self.resetAlbumSelectView()
                    self.tableView.reloadData()
                case .addPhotoDone:
                    break
                }
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
            self.choicePhotoAlbumAction()
        }).disposed(by: disposedBag)
        
        viewModel.getAlbum()
        
        let tapGestureRecognizer = UITapGestureRecognizer()
        tapGestureRecognizer.rx
            .event
            .subscribe(onNext: { [weak self] _ in
                
                guard let self = self else { return }
                self.choicePhotoAlbumAction()
            }).disposed(by: disposedBag)
        
        navigationBarView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    private func choicePhotoAlbumAction() {
        
        tableViewButtonInNavigationBar.isSelected = !tableViewButtonInNavigationBar.isSelected
        tableView.isHidden = !tableViewButtonInNavigationBar.isSelected
    }
    
    private func resetAlbumSelectView() {
        
        tableViewButtonInNavigationBar.isSelected = false
        tableView.isHidden = true
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationBarView.isHidden = false
        
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
