
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
                return "相册选取"
            case .camera:
                return "扫一扫"
            case .keyIn:
                return "手动输入"
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
        tableView.backgroundColor = .menuBackgroundColor
        tableView.register(ChoseTableViewCell.self, forCellReuseIdentifier: ChoseTableViewCell.description())
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        } 
        return tableView
    }()
    
    private let choseEvnets: [ChoseEvnet] = [.photo, .camera, .keyIn]
    
    private let cellHeight: CGFloat = ScaleWidth(at: 55)
    
    private let disposeBag: DisposeBag = .init()
    
    private let dissMissView: UIView = {
        
        let view = UIView()
        view.setBackgroundColor(.dissmissCoverColor)
        return view
    }()
    
    private let bottomCoverView: UIView = {
        
        let view = UIView()
        view.setBackgroundColor(.menuBackgroundColor)
        return view
    }()
    
    private var nowBottomY: CGFloat = 0  {
           
        didSet {

            if nowBottomY < 0 {

                nowBottomY = 0
                tableView.changeBottom(to: 0)
            } else {
                
                if nowBottomY > tableViewBaseHeight {
                    
                    if oldValue < tableViewBaseHeight {
                        
                        tableView.changeBottom(to: tableViewBaseHeight)
                    }
                    bottomCoverView.changeTop(to: (nowBottomY - tableViewBaseHeight))
                } else {
                    tableView.changeBottom(to: nowBottomY)
                    bottomCoverView.changeTop(to: 0)
                }
                
                if nowBottomY > tableViewBaseHeight + bottomHeight + 10 {
                    
                    nowBottomY = tableViewBaseHeight + bottomHeight + 10
                }
            }
        }
    }
    
    private var nowGesY: CGFloat = 0
    
    private lazy var tableViewBaseHeight: CGFloat = cellHeight * CGFloat(integerLiteral: choseEvnets.count)

    private var bottomHeight: CGFloat = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(dissMissView)
        addSubview(bottomCoverView)
        addSubview(tableView)
        
        dissMissView.snp.makeConstraints {
            
            $0.left.right.top.equalToSuperview()
            $0.bottom.equalTo(tableView.snp.top)
        }
        
        tableView.snp.makeConstraints {
            
            $0.left.right.equalToSuperview()
            $0.height.equalTo((cellHeight * CGFloat(integerLiteral: choseEvnets.count)))
            $0.bottom.equalTo(bottomCoverView.snp.top)
        }
        
        bottomCoverView.snp.makeConstraints {
            
            $0.top.equalTo(self.snp.bottomMargin)
            $0.left.right.bottom.equalToSuperview()
        }
        isHidden = true
        layoutIfNeeded()
        superview?.layoutIfNeeded()
        bottomHeight = bottomCoverView.frame.height
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
        
        let panGestureRecognizer = UIPanGestureRecognizer()
        
        addGestureRecognizer(panGestureRecognizer)
        panGestureRecognizer.rx.event
            .subscribe(onNext: { [weak self] panGestureRecognizer in
                guard let self = self else { return }
                
                if panGestureRecognizer.state == .began {
                    
                    self.nowGesY = 0
                } else if panGestureRecognizer.state == .changed {
                    
                    let transLationY = panGestureRecognizer.translation(in: self).y
                    let moveY = self.nowGesY - transLationY
                    self.nowGesY = transLationY
                    self.nowBottomY -= moveY
                    
                } else if panGestureRecognizer.state == .ended {
                    
                    if self.nowBottomY >= self.tableViewBaseHeight / 2 {
                        
                        self.dismissView()
                    } else {
                        
                        self.showView()
                    }
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
            self.nowBottomY = 0
            self.layoutIfNeeded()
        }) { _ in
            
            self.bottomHeight = self.bottomCoverView.frame.height
        }
    }
    
    func dismissView() {
                
        UIView.animate(withDuration: 0.3, animations: {
                   
            self.dissMissView.alpha = 0
            self.nowBottomY = self.bottomHeight + self.tableViewBaseHeight
            self.layoutIfNeeded()
        }, completion: { _ in
                   
            
            self.isHidden = true
        })
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
            .setTextColor(.menuTextColor)
        return label
    }()
    
    private let underLineView: UIView = {
        
        let view = UIView()
        view.setBackgroundColor(.menuUnderLineColor)
        return view
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        contentView.addSubview(titleImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(underLineView)
        contentView.backgroundColor = .menuBackgroundColor
        titleImageView.snp.makeConstraints {
            
            $0.left.equalTo(ScaleWidth(at: 20))
            $0.size.equalTo(ScaleWidth(at: 20))
            $0.centerY.equalToSuperview()
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
