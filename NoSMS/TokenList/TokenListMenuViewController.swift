//
//  TokenListMenuController.swift
//  NoSMS
//
//  Created by azure on 2020/3/5.
//

import UIKit
import RxSwift
import RxCocoa

class ChoseToAddTokenView: UIView {
    
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
        tableView.backgroundColor = .white
        tableView.register(ChoseTableViewCell.self, forCellReuseIdentifier: ChoseTableViewCell.description())
        return tableView
    }()
    
    private let choseEvnets: [ChoseEvnet] = [.photo, .camera, .keyIn]
    
    private let cellHeight: CGFloat = ScaleWidth(at: 55)
    
    private let disposeBag: DisposeBag = .init()
    
//    private let dissMissView: UIView = {
//
//        let view = UIView()
//        view.setBackgroundColor(.backCoverColor)
//        return view
//    }()
//
//    private let bottomCoverView: UIView = {
//
//        let view = UIView()
//        view.setBackgroundColor(.white)
//        return view
//    }()
    
//    private var nowBottomY: CGFloat = 0  {
//
//        didSet {
//
//            if nowBottomY < 0 {
//
//                nowBottomY = 0
//                tableView.changeBottom(to: 0)
//            } else {
//
//                if nowBottomY > tableViewBaseHeight {
//
//                    if oldValue < tableViewBaseHeight {
//
//                        tableView.changeBottom(to: tableViewBaseHeight)
//                    }
////                    bottomCoverView.changeTop(to: (nowBottomY - tableViewBaseHeight))
//                } else {
//                    tableView.changeBottom(to: nowBottomY)
////                    bottomCoverView.changeTop(to: 0)
//                }
//
//                if nowBottomY > tableViewBaseHeight + bottomHeight + 10 {
//
//                    nowBottomY = tableViewBaseHeight + bottomHeight + 10
//                }
//            }
//        }
//    }
    
    private var nowGesY: CGFloat = 0
    
    private lazy var tableViewBaseHeight: CGFloat = cellHeight * CGFloat(integerLiteral: choseEvnets.count)

    private var bottomHeight: CGFloat = 0
    var isDismissView:Bool = true
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(tableView)
                
        tableView.snp.makeConstraints {
            $0.top.left.right.bottom.equalTo(self)
            $0.height.equalTo((cellHeight * CGFloat(integerLiteral: choseEvnets.count)))
        }
        
        layoutIfNeeded()
        superview?.layoutIfNeeded()
//        bottomHeight = bottomCoverView.frame.height
//        dismissView()
        
//        let gesture = UITapGestureRecognizer()
//        dissMissView.addGestureRecognizer(gesture)
//        gesture.rx.event.subscribe(onNext: { [weak self] eve in
            
//            self?.dismissView()
//        }).disposed(by: disposeBag)
        
        tableView.rx.itemSelected.subscribe(onNext: { [weak self] indexPath in
            
            guard let self = self else { return }
//            if self.isDismissView {
//                self.dismissView()
//            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                
                self.chosePhoto.onNext(self.choseEvnets[indexPath.row])
            }
        }).disposed(by: disposeBag)
        

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    

}
extension ChoseToAddTokenView: UITableViewDelegate, UITableViewDataSource {
    
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


protocol TokenListMenuVCViewModelProtocol: BaseTableViewVCViewModelProtocol {
    
}
class TokenListMenuVCViewModel: BaseVCViewModel, TokenListMenuVCViewModelProtocol  {
    var cellViewModels: [BaseTableViewSectionItemsProtocol] = []
    
    var tableViewStyle: UITableView.Style {
        
        return .grouped
    }
    
    init() {
        super.init(navigationItem: BaseNavigaitonItem(title: .init(value: "")), backgroundColor: .white)
    }
//    var navigationItemViewModel: BaseNavigaitonItemProtocol
//
//    var vcBackgroundColor: BehaviorSubject<UIColor>
    
    
//    var cellViewModels: [BaseTableViewSectionItemsProtocol] = []
//
//    var tableViewStyle: UITableView.Style
//
//    var navigationItemViewModel: BaseNavigaitonItemProtocol
//
//    var vcBackgroundColor: BehaviorSubject<UIColor>
    
    
}
class TokenListMenuViewController<VCViewModel: TokenListMenuVCViewModelProtocol>: BaseTableViewController<VCViewModel>{
    let choseToAddTokenView: ChoseToAddTokenView = .init(frame: .zero)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(self.choseToAddTokenView)
        choseToAddTokenView.snp.makeConstraints {
            $0.top.bottom.left.right.equalToSuperview()
        }
       
//        self.choseToAddTokenView.showView()
    }
    
}
