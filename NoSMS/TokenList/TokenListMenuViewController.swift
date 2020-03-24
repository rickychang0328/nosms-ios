//
//  TokenListMenuController.swift
//  NoSMS
//
//  Created by azure on 2020/3/5.
//

import UIKit
import RxSwift
import RxCocoa
class MyPopoverBackgroundView : UIPopoverBackgroundView {

    override class func arrowBase() -> CGFloat {
        if #available(iOS 12.0, *) {
            return 22
        }else{
            return 16
        }
        
    }
    override class func arrowHeight() -> CGFloat { return 12 }
    override class var wantsDefaultContentAppearance: Bool {
        get {
            return false
        }
    }
    override class func contentViewInsets() -> UIEdgeInsets {
//        return UIEdgeInsets(top: 20,left: 20,bottom: 20,right: 20)
//        return UIEdgeInsets(top: 10,left: -12,bottom: -10,right: -12)
        return UIEdgeInsets(top: 0,left: 0,bottom: 0,right: 0)
    }

    // inherits:
    // @property (nonatomic, readwrite) UIPopoverArrowDirection arrowDirection
    // @property (nonatomic, readwrite) CGFloat arrowOffset
    // we are required to reimplement these, even trivially
    // for some reason it is not enough to call super! very weird
    var arrOff : CGFloat
    var arrDir : UIPopoverArrowDirection
    override var arrowDirection : UIPopoverArrowDirection {
        get { return self.arrDir }
        set { self.arrDir = newValue }
    }
   private var _arrowOffset: CGFloat = 0
    override var arrowOffset: CGFloat {
        get { return _arrowOffset }
        set { _arrowOffset = newValue }
    }

    override init(frame:CGRect) {
        self.arrOff = 0
        self.arrDir = .any
        let shadowColor:UIColor = .clear
        super.init(frame:frame)
//        let imageView = UIImageView(frame: CGRect(x:0,y:0,width:ScaleWidth(at: 144),height:ScaleHeight(at: 150)))
//        imageView.image = UIImage(named: "NoSMS_popBack")!
//        imageView.layer.cornerRadius = 5
//        imageView.clipsToBounds = true
//        addSubview(imageView)
//        imageView.snp.makeConstraints{
//            $0.top.equalTo(MyPopoverBackgroundView.arrowHeight())
//            $0.left.right.bottom.equalToSuperview()
//        }
       
//        self.layer.shadowOpacity
        self.layer.shadowColor = shadowColor.cgColor
        self.layer.shadowOpacity = 0
        self.layer.shadowOffset = CGSize(width: -5, height:-5)
        self.layer.shadowRadius = 0
        self.backgroundColor = .clear
//        self.isOpaque = false
    }

    required init(coder: NSCoder) {
        fatalError("NSCoding not supported")
    }

    override func draw(_ rect: CGRect) {
        // WARNING: this code is sort of a cheat:
        // I should be checking self.arrowDirection and changing what I do depending on that...
        // but instead I am just *assuming* that the arrowDirection is UIPopoverArrowDirectionUp

        var linOrig = UIImage(named: "NoSMS_popBack")!
        
        let capw = linOrig.size.width / 2.0 - 1
        let caph = linOrig.size.height / 2.0 - 1
        let lin = linOrig.resizableImage(
            withCapInsets:UIEdgeInsets(top: caph, left: capw, bottom: caph, right: capw),
            resizingMode:.tile)

        let arrowHeight = Self.arrowHeight()
        let arrowBase = Self.arrowBase()

        // draw the arrow
        // I'm just going to make a triangle filled with our linen background...
        // ...extended by a rectangle so it joins to our "pinked" corner drawing

        var arrow : Bool {return true} // false to omit arrow, cute technique
        if arrow {

            let con = UIGraphicsGetCurrentContext()!
            con.saveGState()
            // clamp offset
            let propX =  self.arrowOffset
//            var propX:CGFloat = UIScreen.main.bounds.width > 375 ? 26.0  :13.0
//            let propX:CGFloat = 0.0
//            print("arrow offset:\(propX)")
//            let limit : CGFloat = arrowBase
            //調整箭頭位置
//            print("device name:\(UIDevice.current.name)")
//            let isChangeLimit = UIDevice.current.name == "iPhone SE"
//            print("device width:\(UIScreen.main.bounds.width)")
//            let isChangeLimit = UIScreen.main.bounds.width < 375
//            let limit : CGFloat = isChangeLimit ? 14 : 18
//            let limit:CGFloat = 25
//            propX = min(max(propX, limit), maxX)
//            propX = min(propX,limit)
//            propX = limit
            // draw!
            var x:CGFloat = 0
            var y:CGFloat = 0
            
            if #available(iOS 12.0, *) {
                x = CGFloat(roundf(Float(rect.size.width/2.0 + propX - arrowBase/2.0)))
            }
            else {
                let otherOffset:CGFloat = 3.0
                x = CGFloat(roundf(Float(rect.size.width/2.0 + propX - arrowBase/2.0 - otherOffset)))
                y = 2.0
            }
            
//            let x:CGFloat = 74
            print("arrow offset:\(self.arrowOffset),arrow x:\(x),rect x:\(rect.origin.x),rect width:\(rect.size.width)")
            con.translateBy(x: x, y: y)
            con.move(to:CGPoint(x: 0, y: arrowHeight))
            con.addLine(to:CGPoint(x: arrowBase / 2.0, y: y))
            con.addLine(to:CGPoint(x: arrowBase, y: arrowHeight))
            con.closePath()
//            con.addRect(CGRect(x: 0,y: arrowHeight,width: arrowBase,height: 15))
            con.addRect(CGRect(x: 0,y: arrowHeight,width: arrowBase,height: 15))
            con.clip()
            lin.draw(at:CGPoint(x: -40,y: -40))
            con.restoreGState()

        }

        // draw the body, to go behind the view part of our rectangle (i.e. rect minus arrow)
        let (_,body) = rect.divided(atDistance: arrowHeight, from: .minYEdge)
        lin.draw(in:body)

    }


}
class ChoseAddTableViewCell: UITableViewCell {
    
    private let titleImageView: UIImageView = {
       
        let imageView = UIImageView()
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        
        let label = UILabel()
        label.setFont(.pingFangMediumFont(size: 15))
            .setTextColor(.choseToAddLabelTitleTextColor)
        return label
    }()
    
    private let underLineView: UIView = {
        
        let view = UIView()
        view.backgroundColor = .choseToAddTokenLineColor
//        view.backgroundColor = .black
        return view
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        contentView.addSubview(titleImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(underLineView)
        
        titleImageView.snp.makeConstraints {
            
            $0.left.equalTo(ScaleWidth(at: 24))
            $0.size.equalTo(ScaleWidth(at: 20))
            $0.centerY.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints {
            
            $0.centerY.equalTo(titleImageView)
            $0.left.equalTo(titleImageView.snp.right).offset(ScaleWidth(at: 10))
            $0.right.equalTo(ScaleWidth(at: -20))
        }
        
        underLineView.snp.makeConstraints {
            $0.left.equalTo(ScaleWidth(at: 10))
            $0.right.equalTo(ScaleWidth(at: -10))
            $0.bottom.equalTo(0)
//            $0.height.equalTo(ScaleWidth(at: 1))
            $0.height.equalTo(1)
        }
//        underLineView.isHidden = true
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
    private var backgroundView:UIImageView = UIImageView(frame: .zero)
        
    private lazy var tableView: UITableView = {
        
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.bounces = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.isScrollEnabled = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = .choseToAddTokenViewBackgroundColor
        tableView.register(ChoseAddTableViewCell.self, forCellReuseIdentifier: ChoseAddTableViewCell.description())
        tableView.layer.cornerRadius  = 5
        tableView.clipsToBounds = true
        return tableView
    }()
    
    private let choseEvnets: [ChoseEvnet] = [.photo, .camera, .keyIn]
    
    private let cellHeight: CGFloat = ScaleWidth(at: 50)
    
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
        addSubview(backgroundView)
        addSubview(tableView)
                // User Interface is Dark
                backgroundView.image = UIImage(named:"NoSMS_popBack")
       
        
        backgroundView.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.height.equalTo((cellHeight * CGFloat(integerLiteral: choseEvnets.count)))
        }
        
        tableView.snp.makeConstraints {
            $0.left.right.equalTo(self)
//            $0.top.equalTo(10)
            $0.height.equalTo((cellHeight * CGFloat(integerLiteral: choseEvnets.count)))
        }
        tableView.separatorStyle = .none
        tableView.separatorColor = .clear
//        tableView.separatorColor = .init(red: 190/255, green: 192/255, blue: 201/255, alpha: 0.4)
//        tableView.rx.willDisplayCell.subscribe(onNext: { cell, indexPath in
        //Do your will display logic
//            cell.separatorInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
//        })
//             .disposed(by: disposeBag)
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
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ChoseAddTableViewCell.description(), for: indexPath) as? ChoseAddTableViewCell else {
            
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
class TokenListMenuViewController<VCViewModel: TokenListMenuVCViewModelProtocol>: BaseViewController<VCViewModel>{
    let choseToAddTokenView: ChoseToAddTokenView = .init(frame: .zero)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(self.choseToAddTokenView)
        choseToAddTokenView.snp.makeConstraints {
            $0.top.left.right.equalTo(0)
            $0.bottom.equalTo(0)
        }
        self.view.backgroundColor = .choseToAddTokenViewBackgroundColor
        self.view.isOpaque = false
        choseToAddTokenView.backgroundColor = .choseToAddTokenViewBackgroundColor
        choseToAddTokenView.isOpaque = false
    }

    override func viewDidLayoutSubviews() {
        if #available(iOS 12.0, *) {
            self.view.superview?.snp.makeConstraints{
                $0.top.equalTo(5)
                $0.left.right.bottom.equalToSuperview()
            }
            
        }else{
            self.view.superview?.snp.makeConstraints{
                $0.top.equalTo(10)
                $0.left.right.bottom.equalToSuperview()
            }
        }
        
        
        self.view.superview?.layer.cornerRadius  = 5
        self.view.superview?.clipsToBounds = true
        self.view.superview?.superview?.layer.cornerRadius  = 5
        self.view.superview?.superview?.clipsToBounds = true
    }
}
