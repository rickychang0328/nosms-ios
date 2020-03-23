
import UIKit
import RxCocoa
import RxSwift

protocol PhotoCheckCollectionViewCellViewModelProtocol {
    
    var imageData: BehaviorSubject<UIImage?> { get }
    
    func image(targetSize: CGSize) -> Observable<UIImage?>
}

struct PhotoCheckCollectionViewCellViewModel: PhotoCheckCollectionViewCellViewModelProtocol {
    
    private let photoObject: PhotoObject
    
    var imageData: BehaviorSubject<UIImage?> {
        
        return photoObject.photoImage
    }
    
    init(photoObject: PhotoObject) {
        
        self.photoObject = photoObject
    }
    
    func image(targetSize: CGSize) -> Observable<UIImage?> {
        
        return photoObject.image(targetSize: targetSize)
    }
}


class PhotoCheckTableViewCellViewModel: BaseTableViewCellViewModelProtocol {
    
    let baseCellItem: BaseTableViewCellViewModelItemProtocol = BaseTableViewCellViewModelItem(cellSelectionStyle: .init(value: .none), cellHeight: UITableView.automaticDimension, cellBackgroundColor: .init(value: .clear), cellContentViewBGColor: .init(value: .photoCheckTableViewCellBackgroundColor))
    
    var cellFactoryType: TableViewCellFactoryType { return .photoCheckTableViewCell(viewModel: self)}
        
    let photoObject: PhotoObject
    
    let title: BehaviorSubject<String?>
    
    let photoCount: BehaviorSubject<String>
    
    let isSelected: BehaviorSubject<Bool>
    
    internal init(photoObject: PhotoObject,
                  title: BehaviorSubject<String?>,
                  photoCount: BehaviorSubject<String>,
                  isSelected: BehaviorSubject<Bool>) {
        self.photoObject = photoObject
        self.title = title
        self.photoCount = photoCount
        self.isSelected = isSelected
    }
    
    func getImage(targetSize: CGSize) -> Observable<UIImage?> {
        
        return photoObject.image(targetSize: targetSize)
    }
}

class PhotoCheckTableViewCell: BaseTableViewCell<PhotoCheckTableViewCellViewModel> {
    
    private let titleImageView: UIImageView = {
       
        let imageView: UIImageView = .init()
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label: UILabel = .init()
        label.setFont(.pingFangMediumFont(size: 15))
            .setTextColor(.white)
        return label
    }()
    
    private let countLabel: UILabel = {
        let label: UILabel = .init()
        label.setFont(.pingFangMediumFont(size: 15))
            .setTextColor(.photoCheckCountLabelColor)
        return label
    }()
    
    private let selectedImageView: UIImageView = {
       
        let imageView: UIImageView = .init()
        imageView.image = .noSmsDoneBlue
        return imageView
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        addSubview(titleImageView)
        addSubview(titleLabel)
        addSubview(countLabel)
        addSubview(selectedImageView)
        
        titleImageView.snp.makeConstraints {
            
            $0.left.equalTo(ScaleWidth(at: 3))
            $0.top.equalTo(ScaleWidth(at: 3))
            $0.size.equalTo(ScaleWidth(at: 60))
        }
        
        titleLabel.snp.makeConstraints {
            
            $0.top.equalTo(ScaleWidth(at: 22.5))
            $0.bottom.equalTo(ScaleWidth(at: -22.5)).priorityLow()
            $0.left.equalTo(titleImageView.snp.right).offset(ScaleWidth(at: 15))
        }
        
        countLabel.snp.makeConstraints {
            
            $0.left.equalTo(titleLabel.snp.right).offset(ScaleWidth(at: 15))
            $0.centerY.equalTo(titleLabel)
        }
        
        selectedImageView.snp.makeConstraints {
            
            $0.right.equalTo(ScaleWidth(at: -20))
            $0.size.equalTo(ScaleWidth(at: 25))
            $0.centerY.equalTo(titleLabel)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func bindData(viewModel: PhotoCheckTableViewCellViewModel) {
        super.bindData(viewModel: viewModel)
        
        layoutIfNeeded()
        viewModel.title.bind(to: titleLabel.rx.text).disposed(by: disposedBag)
        
        viewModel.getImage(targetSize: .init(width: titleImageView.bounds.width * 3, height: titleImageView.bounds.height * 3))
            .bind(to: titleImageView.rx.image)
            .disposed(by: disposedBag)
        
        viewModel.photoCount.bind(to: countLabel.rx.text).disposed(by: disposedBag)
        
        viewModel.isSelected.map({!$0}).bind(to: selectedImageView.rx.isHidden).disposed(by: disposedBag)
    }
}

class PhotoCheckCollectionViewCell: UICollectionViewCell {
    
    private let imageView: UIImageView = .init()
    
    var disposeBag: DisposeBag = .init()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(imageView)
        
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = true
        imageView.snp.makeConstraints {
            
            $0.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = .init()
    }
    
    func setupCell(viewModel: PhotoCheckCollectionViewCellViewModelProtocol) {
        
        layoutIfNeeded()
        viewModel.image(targetSize: .init(width: imageView.bounds.width * 4, height: imageView.bounds.height * 4))
            .subscribeOn(CurrentThreadScheduler.instance)
            .observeOn(MainScheduler.instance)
            .bind(to: imageView.rx.image)
            .disposed(by: disposeBag)
        
    }
}
