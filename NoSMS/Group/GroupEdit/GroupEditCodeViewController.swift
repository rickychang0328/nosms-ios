

import UIKit
import RxSwift
import RxCocoa

protocol GroupEditCodeVCViewModelType: BaseTableViewVCViewModelProtocol {
    
    var rightBarTitle: String { get }
    var groupName: BehaviorSubject<String?> { get }
    var groupCodes: [Data] { get }
    var newCodeAddGroup: BehaviorSubject<[Data]> { get }
    var eventResult: Observable<GroupEditCodeVCViewModel.Event> { get }
    var actionButtonEnable: Observable<Bool> { get }
    func removeCode(index: IndexPath)
    func doneAction()
    func viewWillAppear()
    func viewWillDissapper()
}

class GroupEditCodeVCViewModel: BaseVCViewModel, GroupEditCodeVCViewModelType {
    
    func removeCode(index: IndexPath) {
        
        let id = suppot.getTokenID(at: index)
        
        if let idIndex = newEditGroupObject.tokens.firstIndex(of: id) {
            
            newEditGroupObject.tokens.remove(at: idIndex)
        }
        
        let groupViewModels = viewModels.filter({ self.newEditGroupObject.tokens.contains($0.tokenID)})
        suppot.setupTokens(tokens: groupViewModels)
        event.onNext(.reloadData)
        actionBehavior.onNext(actionEnable)
    }
    
    var actionButtonEnable: Observable<Bool> {
        
        return actionBehavior.asObservable()
    }
    
    private let actionBehavior: BehaviorSubject<Bool> = .init(value: false)
    
    private var actionEnable: Bool {
        
        return !newEditGroupObject.title.isEmpty && !newEditGroupObject.tokens.isEmpty
            && ((newEditGroupObject.title != oldGroupObject.title) || (Set(arrayLiteral: newEditGroupObject.tokens) != Set(arrayLiteral: oldGroupObject.tokens)))
    }
    
    
    var eventResult: Observable<GroupEditCodeVCViewModel.Event> {
        
        return event.asObservable()
    }
    
    private let event: PublishSubject<GroupEditCodeVCViewModel.Event> = .init()
    
    enum Event {
        
        case reloadData
    }
    
    var groupCodes: [Data] {
        
        return newEditGroupObject.tokens
    }
    
    let oldGroupObject: GroupObject
    
    var newEditGroupObject: GroupObject
    
    private var viewLifeDisposedBag: DisposeBag = .init()
    
    let newCodeAddGroup: BehaviorSubject<[Data]> = .init(value: [])
    
    init() {
        
        self.oldGroupObject = GroupObject(title: "", uuid: UUID(), tokens: [])
        self.newEditGroupObject = GroupObject(title: self.oldGroupObject.title, uuid: self.oldGroupObject.uuid, tokens: self.oldGroupObject.tokens)
        self.rightBarTitle = "创建"
        self.groupName = .init(value: self.oldGroupObject.title)
        super.init(navigationItem: BaseNavigaitonItem(title: .init(value: "创建分组")), backgroundColor: .clear)
        addObserver()
    }
    
    init(groupID: UUID) {
        
        //TODO: Singleton
        self.oldGroupObject = KeychainTokenStore.shared.getGroup(uuid: groupID) ?? GroupObject(title: "",
                                                                                               uuid: UUID(),
                                                                                               tokens: [])
        self.newEditGroupObject = GroupObject(title: self.oldGroupObject.title, uuid: self.oldGroupObject.uuid, tokens: self.oldGroupObject.tokens)
        self.rightBarTitle = "保存"
        self.groupName = .init(value: self.oldGroupObject.title)
        super.init(navigationItem: BaseNavigaitonItem(title: .init(value: "编辑分组")), backgroundColor: .clear)
        addObserver()
    }
    
    func addObserver() {
        
        newCodeAddGroup.subscribe(onNext: { [weak self] tokenIDs in
            guard let self = self else { return }
            self.newEditGroupObject.tokens = self.newEditGroupObject.tokens + tokenIDs
            self.actionBehavior.onNext(self.actionEnable)
        }).disposed(by: disposedBag)
        
        groupName.subscribe(onNext: { [weak self] title in
            guard let self = self else { return }
            self.newEditGroupObject.title = title ?? ""
            self.actionBehavior.onNext(self.actionEnable)

            }).disposed(by: disposedBag)
    }
    
    func viewWillAppear() {
        //TODO: Singleton
        KeychainTokenStore.shared.persistentTokensBehavior
                   .map({$0.map({GroupEditTableViewCellViewModel(token: $0)})})
                   .subscribe(onNext: { [weak self] viewModels in
                       
                        guard let self = self else { return }
                        
                        self.viewModels = viewModels
                        let groupViewModels = viewModels.filter({ self.newEditGroupObject.tokens.contains($0.tokenID)})
                        self.suppot.setupTokens(tokens: groupViewModels)
                        self.event.onNext(.reloadData)
                   }).disposed(by: viewLifeDisposedBag)
    }
    
    private var viewModels: [GroupEditTableViewCellViewModel] = []
    
    func viewWillDissapper() {
        
        viewLifeDisposedBag = .init()
    }
    
    private let suppot: TokenListSupportPin = .init()
    
    let rightBarTitle: String
    
    let groupName: BehaviorSubject<String?>
    
    func doneAction() {
        
        //TODO: Singleton
        KeychainTokenStore.shared.saveGroup(groupID: newEditGroupObject)
    }
    
    var cellViewModels: [BaseTableViewSectionItemsProtocol] {
        
        return suppot.sections
    }
    
    var tableViewStyle: UITableView.Style { return .grouped }
}

class GroupEditCodeViewController: BaseTableViewControllerNoGeneric {
    
    private lazy var rightNavigationItem: UIBarButtonItem = {
        
        let barButton = UIBarButtonItem(title: viewModel.rightBarTitle, style: .done, target: nil, action: nil)
        barButton.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.pingFangMediumFont(size: 14)], for: .normal)
        barButton.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.pingFangMediumFont(size: 14)], for: .disabled)
        barButton.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.pingFangMediumFont(size: 14)], for: .highlighted)
        return barButton
    }()
    
    private let headerView: GroupEditTableHeaderView = .init(frame: .init(x: 0, y: 0, width: ScaleWidth(at: 375), height: ScaleWidth(at: 164)))
    
    private let viewModel: GroupEditCodeVCViewModelType
    
    init(viewModel: GroupEditCodeVCViewModelType) {
        
        self.viewModel = viewModel
        super.init(baseTableViewModel: viewModel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = rightNavigationItem
        
        tableView.tableHeaderView = headerView
        
        //MARK: RightNavButtonSetup
        rightNavigationItem.rx.tap
            .subscribe(onNext: { [weak self] in
              
                guard let self = self else { return }
                self.viewModel.doneAction()
                self.navigationController?.popViewController(animated: true)
            }).disposed(by: disposedBag)
        viewModel.actionButtonEnable.bind(to: rightNavigationItem.rx.isEnabled).disposed(by: disposedBag)
        
        viewModel.groupName.bind(to: headerView.textField.rx.text).disposed(by: disposedBag)
        headerView.textField.customObserverText.distinctUntilChanged().bind(to: viewModel.groupName).disposed(by: disposedBag)
                
        
        headerView.button.rx.tap.subscribe(onNext: { [weak self] in
            guard let self = self else { return }
            
            if self.headerView.textField.isFirstResponder {
                
                self.headerView.textField.resignFirstResponder()
            }
            
            let vc = GroupAddCodeViewController(viewModel: GroupAddCodeVCViewModel(groupCode: self.viewModel.groupCodes, addTokenIDs: self.viewModel.newCodeAddGroup))
            
            self.navigationController?.pushViewController(vc, animated: true)
            }).disposed(by: disposedBag)
        
        viewModel.eventResult.subscribe(onNext: { [weak self] event in
            guard let self = self else { return }
            switch event {
                
            case .reloadData:
                
                self.tableView.reloadData()
            }
            }).disposed(by: disposedBag)
        tableView.rx.itemDeleted
            .subscribe(onNext: viewModel.removeCode(index:))
            .disposed(by: disposedBag)
        tableView.backgroundColor = .tokenListTableViewBackgroundColor
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        viewModel.viewWillAppear()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        viewModel.viewWillDissapper()
    }
    
    private func getSwipActionPullView(view: UIView) {
        
        view.backgroundColor = .groupEditCellDeleteActionColor
        
        view.frame = .init(origin: view.frame.origin, size: .init(width: view.frame.width, height: view.frame.height - ScaleWidth(at: 4)))
        
        let custom = GroupEditDeleteActionView(frame: .zero)
        
        for button in view.subviews {
            
            if button.description.contains("UISwipeActionStandardButton") {
                
                button.backgroundColor = .groupEditCellDeleteActionColor
                button.isHidden = true
                view.addSubview(custom)
                custom.snp.makeConstraints {
                    
                    $0.edges.equalTo(button)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, willBeginEditingRowAt indexPath: IndexPath) {
                
        if #available(iOS 13, *) {
            
            for iOS13view in tableView.subviews {
                
                if iOS13view.isKind(of: NSClassFromString("_UITableViewCellSwipeContainerView")!) {
                    
                    for view in iOS13view.subviews {
                        
                        if view.isKind(of: NSClassFromString("UISwipeActionPullView")!) {
                            
                            getSwipActionPullView(view: view)
                        }
                    }
                }
            }
        } else if #available(iOS 11, *){
            
            for view in tableView.subviews {
                
                if view.isKind(of: NSClassFromString("UISwipeActionPullView")!) {

                    getSwipActionPullView(view: view)
                }
            }
        } else {
            
            
        }
    }
}

class GroupEditDeleteActionView: UIView {
    
    private let image: UIImageView = .init(image: .noSMSgroupEditRemoveAction)
    private let label: UILabel = {
       
        let label = UILabel()
        label.setText("删除")
            .setFont(.pingFangMediumFont(size: 13))
            .setTextColor(.white)
            .setTextAlignment(.center)
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(image)
        addSubview(label)
        
        //se
        let leftPan: CGFloat
        // 8
        let screenWidth = UIScreen.main.bounds.width

        if UIScreen.main.bounds.width == 375 {
            
            leftPan = 19
        } else if screenWidth > 375 {
            
            leftPan = 17
        } else {
            
            //se
            leftPan = 21
        }
        
        image.snp.makeConstraints {
            
            $0.top.equalTo(ScaleWidth(at: 43))
            $0.left.equalTo(leftPan)
            $0.size.equalTo(ScaleWidth(at: 40))
        }
        
        label.snp.makeConstraints {
            
            $0.centerX.equalTo(image)
            $0.top.equalTo(image.snp.bottom)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


class GroupEditTableHeaderView: UIView, UITextFieldDelegate {
    
    let textField: CustomTextField = {
        
        let textField = CustomTextField()
        textField.addCustomClearButton(rightPan: ScaleWidth(at: 20))
        textField.font = .pingFangMediumFont(size: 15)
        textField.backgroundColor = .groupEditTextFieldBackGroundColor
        textField.leftView = UIView(frame: .init(origin: .init(x: 0, y: 0), size: .init(width: ScaleWidth(at: 20), height: 0)))
        textField.leftViewMode = .always
        textField.textColor = .groupEditTextFieldTextColor
        textField.placeholder = "请输入分组名称"
        return textField
    }()
    
    let button: UIButton = {
       
        let button = UIButton()
        button.setBackgroundColor(.groupEditAddCodeButtonBackGroundColor)
        return button
    }()
    
    private let buttonTitle: UILabel = {
        
        let label = UILabel()
        label.setFont(.pingFangMediumFont(size: 15))
            .setTextAlignment(.right)
            .setTextColor(.groupEditAddCodeButtonColor)
            .setText("添加验证码")
        return label
    }()
    
    private let buttonImage: UIImageView = {
        //TODO:
        let image = UIImageView(image: UIImage.noSMSgroupMenuAdd)
        return image
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .clear
        
        addSubview(textField)
        addSubview(button)
        button.addSubview(buttonTitle)
        button.addSubview(buttonImage)
        
        textField.snp.makeConstraints {
            
            $0.top.leading.right.equalToSuperview()
            $0.height.equalTo(ScaleWidth(at: 60))
        }
        
        button.snp.makeConstraints {
            
            $0.top.equalTo(textField.snp.bottom).offset(ScaleWidth(at: 40))
            $0.left.right.equalToSuperview()
            $0.bottom.equalTo(ScaleWidth(at: -4))
            $0.height.equalTo(ScaleWidth(at: 60))
        }
        
        buttonTitle.snp.makeConstraints {
            
            $0.centerY.equalToSuperview()
            $0.right.equalToSuperview().inset(ScaleWidth(at: 134))
        }
        
        buttonImage.snp.makeConstraints {
            
            $0.centerY.equalToSuperview()
            $0.left.equalToSuperview().inset(ScaleWidth(at: 134))
            $0.size.equalTo(ScaleWidth(at: 20.5))
        }
        
        textField.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField.isFirstResponder {
            
            textField.resignFirstResponder()
        }
        
        return true
    }
    
    //MARK: 限制長度
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = textField.text else { return true }
        if !string.isNameAndIssuerVaild() {
            
            return false
        }
        let newLength = text.count + string.count - range.length
        return newLength <= 10
    }
}

