
import UIKit
import RxCocoa
import RxSwift

class ChoseHowToAddTokenView: UIView {
    
    enum ChoseEvnet {
        
        case photo
        case camera
        case keyIn
        
        fileprivate var image: UIImage {

            switch self {
            
            case .photo:
                return .noSmsPhoto
            case .camera:
                return .noSmsCamera
            case .keyIn:
                return .noSmsKeyin
            }
        }
        
        fileprivate var title: String {
            
            switch self {
            
            case .photo:
                return "相册选取扫描"
            case .camera:
                return "扫描二维码"
            case .keyIn:
                return "手动输入验证码"
            }
        }
    }
    
    let chosePhoto: PublishSubject<ChoseEvnet> = .init()
    
    private lazy var tableView: UITableView = {
        
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.bounces = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isScrollEnabled = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = .white
        tableView.register(ChoseTableViewCell.self, forCellReuseIdentifier: ChoseTableViewCell.description())
        return tableView
    }()
    
    private let choseEvnets: [ChoseEvnet] = [.photo, .camera, .keyIn]
    
    private let cellHeight: CGFloat = ScaleWidth(at: 55)
    
    private let disposeBag: DisposeBag = .init()
    
    private let dissMissView: UIView = {
        
        let view = UIView()
        view.setBackgroundColor(.backCoverColor)
        return view
    }()
    
    private let bottomCoverView: UIView = {
        
        let view = UIView()
        view.setBackgroundColor(.white)
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(dissMissView)
        addSubview(tableView)
        addSubview(bottomCoverView)
        
        dissMissView.snp.makeConstraints {
            
            $0.left.right.top.equalToSuperview()
            $0.bottom.equalTo(tableView.snp.top)
        }
        
        tableView.snp.makeConstraints {
            
            $0.left.right.bottomMargin.equalToSuperview()
            $0.height.equalTo((cellHeight * CGFloat(integerLiteral: choseEvnets.count)))
        }
        
        bottomCoverView.snp.makeConstraints {
            
            $0.top.equalTo(tableView.snp.bottom)
            $0.left.right.bottom.equalToSuperview()
        }
        dismissView()
        
        let gesture = UITapGestureRecognizer()
        dissMissView.addGestureRecognizer(gesture)
        gesture.rx.event.subscribe(onNext: { [weak self] eve in
            
            self?.dismissView()
        }).disposed(by: disposeBag)
        
        tableView.rx.itemSelected.subscribe(onNext: { [weak self] indexPath in
            
            guard let self = self else { return }
            self.dismissView()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                
                self.chosePhoto.onNext(self.choseEvnets[indexPath.row])
            }
        }).disposed(by: disposeBag)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showView() {
        
        isHidden = false
    }
    
    func dismissView() {
        
        isHidden = true
    }
}

extension ChoseHowToAddTokenView: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return choseEvnets.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return cellHeight
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return 0.001
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        return 0.001
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ChoseTableViewCell.description(), for: indexPath) as? ChoseTableViewCell else {
            
            return UITableViewCell()
        }
        let event = choseEvnets[indexPath.row]
        
        let underLineHide: Bool
        
        if indexPath.row == (choseEvnets.count - 1) {
            
            underLineHide = true
        } else {
            
            underLineHide = false
        }
        
        cell.setupCell(image: event.image, title: event.title, underLineHide: underLineHide)
        return cell
    }
}

class ChoseTableViewCell: UITableViewCell {
    
    private let titleImageView: UIImageView = {
       
        let imageView = UIImageView()
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        
        let label = UILabel()
        label.setFont(.pingFangMediumFont(size: 15))
            .setTextColor(.black)
        return label
    }()
    
    private let underLineView: UIView = {
        
        let view = UIView()
        view.setBackgroundColor(.init(red: 190/255, green: 192/255, blue: 201/255, alpha: 0.4))
        return view
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        contentView.addSubview(titleImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(underLineView)
        
        titleImageView.snp.makeConstraints {
            
            $0.left.equalTo(ScaleWidth(at: 20))
            $0.size.equalTo(ScaleWidth(at: 20))
            $0.centerY.equalToSuperview()
//            $0.top.equalTo(ScaleWidth(at: 17.5))
//            $0.bottom.equalTo(ScaleWidth(at: -17.5))
        }
        
        titleLabel.snp.makeConstraints {
            
            $0.centerY.equalTo(titleImageView)
            $0.left.equalTo(titleImageView.snp.right).offset(ScaleWidth(at: 20))
        }
        
        underLineView.snp.makeConstraints {
            
            $0.left.equalTo(ScaleWidth(at: 20))
            $0.right.equalTo(ScaleWidth(at: -20))
            $0.bottom.equalToSuperview()
            $0.height.equalTo(0.5)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupCell(image: UIImage, title: String, underLineHide: Bool) {
        
        titleImageView.image = image
        titleLabel.text = title
        underLineView.isHidden = underLineHide
    }
}
