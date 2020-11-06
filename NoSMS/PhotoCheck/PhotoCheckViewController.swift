
import UIKit
import RxCocoa
import RxSwift
import PhotosUI

protocol PhotoCheckVCViewModelProtocol: BaseTableViewVCViewModelProtocol {
    
    var reloadAlbum: PublishSubject<PhotoCheckVCViewModel.Event> { get }
    var photosCount: Int { get }
    var photoImageData: [PhotoCheckCollectionViewCellViewModelProtocol] { get }
    var newBarViewTitle: BehaviorSubject<String?> { get }
    var isHaveAlbum: Bool { get }
    
    func checkAuth()
    func getPhotoAuth() -> Driver<PHAuthorizationStatus>
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
    
    var isHaveAlbum: Bool { return tableViewSectionItem.numberOfRow != 0 }
    
    func getPhotoAuth() -> Driver<PHAuthorizationStatus> {
        
        return AuthorizationManager.photoLiabraryStatus()
    }
    
    enum Event {
        
        case selectAlbumDone
        case addPhotoDone
        case authDidNotOpen
        case authIslimited
        case getPhoto
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
    
    func checkAuth() {
        
        getPhotoAuth()
            .drive(onNext: { [weak self] status in
                guard let self = self else { return }
                
                switch status {
                
                case .notDetermined:
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        
                        self.checkAuth()
                    }
                case .restricted:
                    self.reloadAlbum.onNext(.authDidNotOpen)
                case .denied:
                    self.reloadAlbum.onNext(.authDidNotOpen)
                case .authorized:
                    self.reloadAlbum.onNext(.getPhoto)
                case .limited:
                    self.reloadAlbum.onNext(.authIslimited)
                @unknown default:
                    break
                }
            }).disposed(by: disposedBag)
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
    
    private let photoCheckAuthView: PhotoCheckAuthView = .init(frame: .zero)
    
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
    
    private func goAuthView() {
        
        view.addSubview(photoCheckAuthView)
        
        photoCheckAuthView.snp.makeConstraints {
            
            $0.edges.equalToSuperview()
        }
        photoCheckAuthView.settingButtonTap
            .subscribe(onNext: { [weak self] in
                self?.showSettingAppAuthPage()
            }).disposed(by: disposedBag)
    }
    
    private func authIslimitedHandler() {
        
        goAuthView()
        photoCheckAuthView.setupView(title: "无法访问相册所有照片",
                                     message: "只能访问相册中的部分照片，建议前往系统设置，允许访问「照片」中的「所有照片」。",
                                     continueButtonIsHidden: false)
        photoCheckAuthView.continueButtonTap
            .subscribe(onNext: { [weak self] in
                self?.goPhotoSetting()
            }).disposed(by: disposedBag)
    }
    
    private func authDidNotOpenHandler() {
        
        let message: String
        
        if #available(iOS 14, *) {
            
            message = "当前无照片访问权限，建议前往系统设置，允许访问「照片」中的「所有照片」。"
        } else {
            
            message = "当前无照片访问权限，建议前往系统设置，允许访问「照片」中的「读取和写入」。"
        }
        
        goAuthView()
        photoCheckAuthView.setupView(title: "无法访问相册中照片",
                                     message: message,
                                     continueButtonIsHidden: true)
    }
    
    fileprivate func goPhotoSetting() {
        
        photoCheckAuthView.isHidden = true
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(PhotoCheckCollectionViewCell.self, forCellWithReuseIdentifier: "PhotoCheckCollectionViewCell.self")
        collectionView.backgroundColor = .photoCheckViewBackgroundColor
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
                
            }).disposed(by: disposedBag)
        
        collectionView.rx.willDisplayCell.map({$0.at.row})
            .subscribe(onNext: { [weak self] index in
                
                guard let self = self else { return }
                if index > self.viewModel.photosCount - 20 {
                    
                    self.viewModel.reloadMorePhoto()
                }
            }).disposed(by: disposedBag)
        
        tableView.isHidden = true
        tableView.bounces = false
        tableView.backgroundColor = .photoChoseCoverColor
        tableView.rx.itemSelected.map({$0.row})
            .subscribe(onNext: { [weak self] index in
                
                self?.viewModel.selectAlbum(index: index)
            }).disposed(by: disposedBag)
        
        
        viewModel.newBarViewTitle.bind(to: navigationNewTitle.rx.text).disposed(by: disposedBag)
        
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
                if self.viewModel.isHaveAlbum {
                    
                    self.choicePhotoAlbumAction()
                }
            }).disposed(by: disposedBag)
        
        navigationBarView.addGestureRecognizer(tapGestureRecognizer)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .any, barMetrics: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        
        viewModel.reloadAlbum
            .subscribe(onNext: { [weak self] event in
                guard let self = self else { return }
                
                self.collectionView.reloadData()
                self.navigationBarView.isHidden = !self.viewModel.isHaveAlbum
                self.tableViewButtonInNavigationBar.isHidden = !self.viewModel.isHaveAlbum
                switch event {
                            
                case .selectAlbumDone:
                    self.resetAlbumSelectView()
                    self.tableView.reloadData()
                case .addPhotoDone:
                    break
                case .authDidNotOpen:
                    self.authDidNotOpenHandler()
                case .authIslimited:
                    self.authIslimitedHandler()
                case .getPhoto:
                    
                    self.goPhotoSetting()
                }
            }).disposed(by: disposedBag)
        
        let leftBarButton = UIBarButtonItem(title: "取消", style: .plain, target: nil, action: nil)
        leftBarButton.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.pingFangMediumFont(size: 16)], for: .normal)
        leftBarButton.rx.tap.subscribe(onNext: { [weak self] _ in
            
            self?.dismiss(animated: true, completion: nil)
        }).disposed(by: disposedBag)
        navigationItem.leftBarButtonItem = leftBarButton
        
        viewModel.checkAuth()
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
    
    private func setupNavigationViewColor() {
        
        let color: UIColor
        
        if UIDevice.isOniOS13UpDarkMode {
            
            color = .navColorDark
        } else {
            
            color = .navColorLight
        }
        navigationBarView.setBackgroundColor(color)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setupNavigationViewColor()
    }
}

class PhotoCheckAuthView: UIView {
    
    private let titleLabel: UILabel = {
        
        let label = UILabel()
        label.setFont(.pingFangRegularFont(size: 18))
            .setTextColor(.photoCheckAuthLabelColor)
        return label
    }()
    
    private let messageLabel: UILabel = {
        
        let label = UILabel()
        label.setFont(.pingFangRegularFont(size: 15))
            .setTextColor(.photoCheckAuthLabelColor)
            .setTextAlignment(.center)
            .setNumberOfLine(0)
        return label
    }()
    
    private let settingButton: UIButton = {
        
        let button = UIButton()
        button.setTitle("前往系统设置", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .pingFangMediumFont(size: 15)
        button.setBackgroundColor(.photoCheckButtonTextAndBackgroundColor)
        button.addCornerRadius(at: ScaleWidth(at: 6))
        
        return button
    }()
    
    private let continueButton: UIButton = {
        
        let button = UIButton()
        button.setTitle("继续访问部分照片", for: .normal)
        button.titleLabel?.font = .pingFangMediumFont(size: 15)
        button.setTitleColor(.photoCheckButtonTextAndBackgroundColor, for: .normal)
        return button
    }()
    
    var continueButtonTap: ControlEvent<Void> {
        
        return continueButton.rx.tap
    }
    
    var settingButtonTap: ControlEvent<Void> {
        
        return settingButton.rx.tap
    }

    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(titleLabel)
        addSubview(messageLabel)
        addSubview(settingButton)
        addSubview(continueButton)
        
        titleLabel.snp.makeConstraints {
            
            $0.centerX.equalToSuperview()
            $0.top.equalTo(ScaleWidth(at: 132))
        }
        
        
        messageLabel.snp.makeConstraints {
            
            $0.top.equalTo(titleLabel.snp.bottom).offset(ScaleWidth(at: 15))
            $0.centerX.equalToSuperview()
        }
        messageLabel.preferredMaxLayoutWidth = ScaleWidth(at: 330)
        
        continueButton.snp.makeConstraints {
            
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(ScaleWidth(at: -81))
            $0.width.equalTo(ScaleWidth(at: 137))
            $0.height.equalTo(ScaleWidth(at: 17))
        }
        
        settingButton.snp.makeConstraints {
            
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(continueButton.snp.top).offset(ScaleWidth(at: -25))
            $0.width.equalTo(ScaleWidth(at: 345))
            $0.height.equalTo(ScaleWidth(at: 42))
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupView(title: String, message: String, continueButtonIsHidden: Bool) {
        
        titleLabel.text = title
        messageLabel.text = message
        continueButton.isHidden = continueButtonIsHidden
    }
}
