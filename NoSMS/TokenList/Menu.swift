
import UIKit
import RxCocoa
import RxSwift

class MenuView: UIView {
    
    enum ChoseEvnet {
        
        case legal
        case privacy
        case service
        case helper
        case versionupdate
        fileprivate var image: UIImage {

            switch self {
            
            case .legal:
                return .noSmsLegal
            case .privacy:
                return .noSmsPrivacy
            case .service, .helper:
                return .noSmsService
            case .versionupdate:
                return .noSmsVersionUpdate
            }
        }
        
        fileprivate var title: String {
            
            switch self {
            
            case .legal:
                return "法律声明"
            case .privacy:
                return "隐私权政策"
            case .service:
                return "服务条款"
            case .helper:
                return "帮助中心"
            case .versionupdate:
                return "关于"
            }
        }
        
        var nextVC: UIViewController {
            
            switch self {

            case .legal:
                return UIViewController()
            case .privacy:
                return PrivacyViewController()
            case .service:
                return UIViewController()
            case .helper:
                return HelperViewController()
            case .versionupdate:
                return VersionUpdateViewController()
            }
        }
        var isShowRedView:Bool {
            switch self {
                case .versionupdate:
                    if let version = Repository.sharedInstance.version {
                        if version.isNeedUpdate ?? false {
                            return true
                        }else{
                           return false
                        }
                    }else {
                        return false
                    }
//                    return true
                default:
                    return false
            }
        }
    }
    
    let choseEvent: PublishSubject<ChoseEvnet> = .init()
    
    private lazy var tableView: UITableView = {
        
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.bounces = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isScrollEnabled = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = .white
        tableView.register(MenuViewTableViewCell.self,
                           forCellReuseIdentifier: MenuViewTableViewCell.description())
        return tableView
    }()
    func reloadTableViewData() {
        self.tableView.reloadData()
    }
    private let choseEvnets: [ChoseEvnet] = [.privacy, .helper,.versionupdate]
    
    private let cellHeight: CGFloat = ScaleWidth(at: 63)
    
    private let disposeBag: DisposeBag = .init()
    
    private let dissMissView: UIView = {
        
        let view = UIView()
        view.setBackgroundColor(.backCoverColor)
        return view
    }()
    
    private var nowTableViewX: CGFloat = 0  {
           
        didSet {

            if nowTableViewX > 0 {

                nowTableViewX = 0
                tableView.changeLeading(to: 0)
            } else {

                tableView.changeLeading(to: nowTableViewX)
            }
        }
    }
    
    private var nowGesX: CGFloat = 0
    
    private let tableViewBaseWitdh: CGFloat = ScaleWidth(at: 290)

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(dissMissView)
        addSubview(tableView)
        
        let panGestureRecognizer = UIPanGestureRecognizer()
        
        addGestureRecognizer(panGestureRecognizer)
        panGestureRecognizer.rx.event
            .subscribe(onNext: { [weak self] panGestureRecognizer in
                guard let self = self else { return }
                
                if panGestureRecognizer.state == .began {
                    
                    self.nowGesX = 0
                } else if panGestureRecognizer.state == .changed {
                    
                    let transLationX = panGestureRecognizer.translation(in: self).x
                    let moveX = self.nowGesX - transLationX
                    self.nowGesX = transLationX
                    self.nowTableViewX -= moveX
                    
                } else if panGestureRecognizer.state == .ended {
                    
                    if self.nowTableViewX >= -self.tableViewBaseWitdh / 2 {
                        
                        self.showView()
                    } else {
                        
                        self.dismissView()
                    }
                }
            }).disposed(by: disposeBag)
        
        dissMissView.snp.makeConstraints {
            
            $0.bottom.right.top.equalToSuperview()
            $0.left.equalTo(tableView.snp.right)
        }
        
        tableView.snp.makeConstraints {
            $0.leading.equalTo((-self.tableViewBaseWitdh))
            $0.top.bottom.equalToSuperview()
            $0.width.equalTo(self.tableViewBaseWitdh)
        }
        
        isHidden = true
        dismissView()
        
        let gesture = UITapGestureRecognizer()
        dissMissView.addGestureRecognizer(gesture)
        gesture.rx.event.subscribe(onNext: { [weak self] eve in
            
            self?.dismissView()
        }).disposed(by: disposeBag)
        
        tableView.rx.itemSelected.subscribe(onNext: { [weak self] indexPath in
            
            guard let self = self else { return }
            self.dismissView {
                
                self.choseEvent.onNext(self.choseEvnets[indexPath.row])
            }
           
        }).disposed(by: disposeBag)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func showView() {
        
        isHidden = false
        
        UIView.animate(withDuration: 0.3, animations: {
            
            self.dissMissView.alpha = 1
            self.nowTableViewX = 0
            self.layoutIfNeeded()
        })
    }
    
    func dismissView(completion: (() -> Void)? = nil) {
        
        
        UIView.animate(withDuration: 0.3, animations: {
                   
            self.dissMissView.alpha = 0
            self.nowTableViewX = -self.tableViewBaseWitdh
            self.layoutIfNeeded()
        }, completion: { _ in
                   
            completion?()
            self.isHidden = true
        })
    }
}

extension MenuView: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return choseEvnets.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return cellHeight
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return ScaleWidth(at: 50.5)
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        
        return 0.001
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MenuViewTableViewCell.description(), for: indexPath) as? MenuViewTableViewCell else {
            
            return UITableViewCell()
        }
        let event = choseEvnets[indexPath.row]
        
        let underLineHide: Bool
        
        
        
        if choseEvnets.count == 1 {
            
            underLineHide = false
        } else if indexPath.row == (choseEvnets.count - 1) {
            
            underLineHide = true
        } else {
            
            underLineHide = false
        }
        
        cell.setupCell(image: event.image, title: event.title, underLineHide: underLineHide,isShowRedView: event.isShowRedView)
        return cell
    }
}

class MenuViewTableViewCell: UITableViewCell {
    
    private let titleImageView: UIImageView = {
       
        let imageView = UIImageView()
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        
        let label = UILabel()
        label.setFont(.pingFangMediumFont(size: 15))
            .setTextColor(.init(red: 51/255, green: 51/255, blue: 51/255, alpha: 1))
        return label
    }()
    
    private let underLineView: UIView = {
        
        let view = UIView()
        view.setBackgroundColor(.init(red: 190/255, green: 192/255, blue: 201/255, alpha: 0.4))
        return view
    }()
    private let updateRedView: UIView = {
           
           let view = UIView()
           view.frame = .init(x: 50, y: 0, width: 8, height: 8)
           view.setBackgroundColor(.red)
           .addCornerRadius(at: 4)
           return view
       }()
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        contentView.addSubview(titleImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(updateRedView)
        contentView.addSubview(underLineView)

        titleImageView.snp.makeConstraints {
            
            $0.left.equalTo(ScaleWidth(at: 20))
            $0.size.equalTo(ScaleWidth(at: 25))
            $0.centerY.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints {
            
            $0.centerY.equalTo(titleImageView)
            $0.left.equalTo(titleImageView.snp.right).offset(ScaleWidth(at: 15))
        }
        updateRedView.snp.makeConstraints{
            $0.width.height.equalTo(8)
            $0.centerY.equalTo(titleImageView)
            $0.right.equalTo(ScaleWidth(at: -10))
        }
        updateRedView.isHidden = true
        underLineView.snp.makeConstraints {
            
            $0.left.equalTo(ScaleWidth(at: 12))
            $0.right.equalTo(ScaleWidth(at: -12))
            $0.bottom.equalToSuperview()
            $0.height.equalTo(0.5)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupCell(image: UIImage, title: String, underLineHide: Bool,isShowRedView:Bool) {
        
        titleImageView.image = image
        titleLabel.text = title
        underLineView.isHidden = underLineHide
        updateRedView.isHidden = !isShowRedView
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        if highlighted {
           
            contentView.backgroundColor = .alertCancelButtonColor
        } else {
           
            contentView.backgroundColor = .white
        }
    }
}
