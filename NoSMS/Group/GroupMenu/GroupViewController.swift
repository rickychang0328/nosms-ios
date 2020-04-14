
import UIKit
import RxSwift
import RxCocoa


protocol GroupSectionType: BaseTableViewSectionItemsProtocol {
    
    func delete(index: Int)
    func getGroupID(index: Int) -> UUID
}

class GroupSection: GroupSectionType {
    
    func getGroupID(index: Int) -> UUID {
        
        return groupList[index].uuid
    }
    
    func delete(index: Int) {
        
        groupList.remove(at: index)
        //TODO:
        KeychainTokenStore.shared.removeGroup(index: index)
    }
    
    let sectionHeaderViewModel: BaseTableViewSectionHeaderFooterViewModelProtocol? = nil
    
    let sectionFooterViewModel: BaseTableViewSectionHeaderFooterViewModelProtocol? = nil
    
    var numberOfRow: Int {
        
        return viewModels.count
    }
    
    subscript(index: Int) -> BaseTableViewCellViewModelProtocol {
        
        return viewModels[index]
    }
    
    private var groupList: [GroupObject] = [] {
        
        didSet {
            
            viewModels = groupList.map({GroupTableViewCellViewModel(isEditing: isEditing, title: $0.title)})
        }
    }
    
    private let isEditing: Observable<Bool>
    
    private let disposedBag: DisposeBag = .init()
    
    private let viewModelEventResult: BehaviorSubject<GroupVCViewModel.Event>
    
    init(isEditing: Observable<Bool>,
         viewModelEventResult: BehaviorSubject<GroupVCViewModel.Event>) {
        
        self.isEditing = isEditing
        self.viewModelEventResult = viewModelEventResult
        
        //TODO:
        KeychainTokenStore.shared
            .groupListBehavior
            .subscribe(onNext: { [weak self] groups in
            
            guard let self = self else { return }
            self.groupList = groups
            
            self.viewModelEventResult.onNext(.reloadData)
        }).disposed(by: disposedBag)
        
        KeychainTokenStore.shared
            .canAddGroup.subscribe(onNext: { [weak self] canAddGroup in
                
                guard let self = self else { return }
                self.viewModelEventResult.onNext(.canAddGroup(canAddGroup))
            }).disposed(by: disposedBag)
    }
    
    private var viewModels: [GroupTableViewCellViewModelType] = []
}

class GroupTableHeaderView: UIView {
    
    private let groupImageView: UIImageView = .init(image: .noSMSgroupMenu)
    
    private let label: UILabel = {
        
        let label = UILabel()
        label.setFont(.pingFangMediumFont(size: 15))
            .setText("创建分组能帮你快速找到所需要的验证码，且更有效的对其进行管理")
            .setTextColor(.groupHeaderTitleColor)
            .setNumberOfLine(2)
        return label
    }()
    
    private let buttonLabel: UILabel = {
        
        let label = UILabel()
        label.setFont(.pingFangMediumFont(size: 15))
            .setText("创建分组")
            .setTextAlignment(.left)
            //TODO:
            .setTextColor(.tokenListTimerColor)
        return label
    }()
    
    private let buttonImage: UIImageView = {
        
        let imageView = UIImageView(image: UIImage.noSMSgroupMenuAdd)
        return imageView
    }()
    
    let addGroupBottom: UIButton = {
        
        let button = UIButton()
        button.setBackgroundColor(.groupBackCardColor)
        return button
    }()
 
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(groupImageView)
        addSubview(label)
        addSubview(addGroupBottom)
        addGroupBottom.addSubview(buttonImage)
        addGroupBottom.addSubview(buttonLabel)
        
        backgroundColor = .clear
        
        groupImageView.snp.makeConstraints {
            
            $0.top.equalTo(ScaleWidth(at: 60))
            $0.centerX.equalToSuperview()
            $0.width.equalTo(ScaleWidth(at: 87.5))
            $0.height.equalTo(ScaleWidth(at: 73.5))
        }
        
        label.snp.makeConstraints {
            
            $0.centerX.equalToSuperview()
            $0.top.equalTo(groupImageView.snp.bottom).offset(ScaleWidth(at: 30))
            $0.width.equalTo(ScaleWidth(at: 249))
        }
                
        addGroupBottom.addCornerRadius(at: ScaleWidth(at: 6))
        addGroupBottom.clipsToBounds = false
        addGroupBottom.layer.shadowOffset = .init(width: 0, height: ScaleWidth(at: 1))
        addGroupBottom.layer.shadowOpacity = 0.07
        
        addGroupBottom.snp.makeConstraints {
            
            $0.left.right.equalToSuperview()
            $0.top.equalTo(label.snp.bottom).offset(ScaleWidth(at: 40))
            $0.height.equalTo(ScaleWidth(at: 60))
        }
        
        buttonImage.snp.makeConstraints {
            
            $0.centerY.equalToSuperview()
            $0.left.equalTo(ScaleWidth(at: 127))
            $0.size.equalTo(ScaleWidth(at: 19.5))
        }
        
        buttonLabel.snp.makeConstraints {
            
            $0.top.bottom.centerY.equalToSuperview()
            $0.right.equalTo(ScaleWidth(at: -127))
            $0.left.equalTo(buttonImage.snp.right).offset(ScaleWidth(at: 8))
        }
        
        clipsToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

protocol GroupVCViewModelType: BaseTableViewVCViewModelProtocol {
    
    var eventResult: Observable<GroupVCViewModel.Event> { get }
    
    func moveGroup(at origin: Int, to destination: Int)
    func deleteGroup(index: Int)
    func getGroupID(index: Int) -> UUID
    func setEditing(isEditing: Bool)
}

class GroupVCViewModel: GroupVCViewModelType {
    
    func setEditing(isEditing: Bool) {
        
        isEditingBehavior.onNext(isEditing)
    }
    
    func moveGroup(at origin: Int, to destination: Int) {
        
        //TODO:
        KeychainTokenStore.shared.moveGroup(origin, toIndex: destination)
    }

    func getGroupID(index: Int) -> UUID {
        
        return groupSection.getGroupID(index: index)
    }
    
    var eventResult: Observable<Event> {
        
        return eventResultBehavior.asObservable()
    }
    
    private let eventResultBehavior: BehaviorSubject<Event> = .init(value: .reloadData)
    
    enum Event {
        
        case reloadData
        case canAddGroup(Bool)
    }
    
    var cellViewModels: [BaseTableViewSectionItemsProtocol] {
        
        return [groupSection]
    }
    
    let tableViewStyle: UITableView.Style = .grouped
    
    let navigationItemViewModel: BaseNavigaitonItemProtocol = BaseNavigaitonItem(title: BehaviorSubject<String>(value: "分组管理"))
    
    let vcBackgroundColor: BehaviorSubject<UIColor> = .init(value: .tokenListTableViewBackgroundColor)
    
    lazy var groupSection: GroupSectionType = GroupSection(isEditing: isEditingBehavior, viewModelEventResult: eventResultBehavior)
    
    private let isEditingBehavior: BehaviorSubject<Bool> = .init(value: false)
    
    func deleteGroup(index: Int) {
        
        groupSection.delete(index: index)
    }
}

class GroupViewController: BaseTableViewControllerNoGeneric {
    
    private let viewModel: GroupVCViewModelType
    
    private let tableHeaderView: GroupTableHeaderView = .init(frame: .init(x: 0, y: 0, width: ScaleWidth(at: 375), height: ScaleWidth(at: 315.5)))
    
    private let rightNavigationItem: UIBarButtonItem = {
        
        let barButton = UIBarButtonItem(title: "编辑", style: .done, target: nil, action: nil)
        barButton.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.pingFangMediumFont(size: 14)], for: .normal)
        barButton.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.pingFangMediumFont(size: 14)], for: .disabled)
        barButton.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.pingFangMediumFont(size: 14)], for: .highlighted)
        return barButton
    }()
    
    init(viewModel: GroupVCViewModelType) {
        
        self.viewModel = viewModel
        super.init(baseTableViewModel: viewModel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.snp.remakeConstraints {
            
            $0.top.bottom.equalToSuperview()
            $0.left.right.equalToSuperview().inset(ScaleWidth(at: 15))
        }

        tableView.shadowViewIsHidden = true
        tableView.tableHeaderView = tableHeaderView
        navigationItem.rightBarButtonItem = rightNavigationItem
        
        rightNavigationItem.rx.tap.subscribe(onNext: { [weak self] in
            
            guard let self = self else { return }
            
            self.tableView.setEditing(!self.tableView.isEditing, animated: true)
            self.viewModel.setEditing(isEditing: self.tableView.isEditing)
            self.setupRightNavButton()
        }).disposed(by: disposedBag)
        
        tableHeaderView.addGroupBottom.rx.tap.subscribe(onNext: { [weak self] in
            
            guard let self = self else { return }
            let vc = GroupEditCodeViewController(viewModel: GroupEditCodeVCViewModel())
            self.navigationController?.pushViewController(vc, animated: true)
            }).disposed(by: disposedBag)
        
        tableView.backgroundColor = .tokenListTableViewBackgroundColor
        
        viewModel.eventResult.subscribe(onNext: { [weak self] event in
            guard let self = self else { return }
            
            switch event {
                
            case .reloadData:
                
                self.tableView.reloadData()
                if self.viewModel.cellViewModels.isEmpty {
                    
                    self.tableView.setEditing(false, animated: true)
                    self.viewModel.setEditing(isEditing: false)
                    self.setupRightNavButton()
                }
            case .canAddGroup(let canAdd):
                
                self.setupHeaderView(canAddGroup: canAdd)
            }
        }).disposed(by: disposedBag)
        
        tableView.rx.itemSelected.subscribe(onNext: { [weak self] indexPath in
            
            guard let self = self else { return }
            self.goEditCodeVC(selectIndexPath: indexPath)
        }).disposed(by: disposedBag)
        
        tableView.rx.itemDeleted
            .map({$0.row}).subscribe(onNext: { [weak self] row in
                guard let self = self else { return }

                self.showStreetDeleteAlert(title: "操作仅删除分组，并不会删除验证码", confirmTitle: "删除", confirmAction: {

                    self.viewModel.deleteGroup(index: row)
                }, cancelAction: {
                    
                    self.tableView.setEditing(false, animated: false)
                    self.tableView.setEditing(true, animated: false)
                })
            }).disposed(by: disposedBag)
        
        tableView.rx.itemMoved
            .map({ ($0.sourceIndex.row, $0.destinationIndex.row)})
            .subscribe(onNext: viewModel.moveGroup)
            .disposed(by: disposedBag)
        
        tableView.customTableViewEvent.subscribe(onNext: { [weak self] event in
            
            guard let self = self else { return }
            self.searchDeleteView()
            
        }).disposed(by: disposedBag)
    }
    
    
    
    private func setupHeaderView(canAddGroup: Bool) {
        
        if canAddGroup {
            
            tableHeaderView.frame = .init(x: 0, y: 0, width: ScaleWidth(at: 375), height: ScaleWidth(at: 315.5))
        } else {
            
            tableHeaderView.frame = .init(x: 0, y: 0, width: ScaleWidth(at: 375), height: ScaleWidth(at: 245.5))
        }
        
        tableView.tableHeaderView = tableHeaderView
        tableHeaderView.addGroupBottom.isHidden = !canAddGroup
    }
    
    private func goEditCodeVC(selectIndexPath: IndexPath) {
        
        let groupID = viewModel.getGroupID(index: selectIndexPath.row)
        let nextVC = GroupEditCodeViewController(viewModel: GroupEditCodeVCViewModel(groupID: groupID))
        
        self.navigationController?.pushViewController(nextVC, animated: true)
    }
    
    private func setupRightNavButton() {
        
        rightNavigationItem.title = tableView.isEditing ? "保存" : "编辑"
    }
    
    private func getSwipActionPullView(view: UIView) {
        
        view.backgroundColor = .groupEditCellDeleteActionColor
        view.frame = .init(origin: .init(x: view.frame.origin.x + ScaleWidth(at: 10), y: view.frame.origin.y), size: .init(width: view.frame.width, height: view.frame.height - ScaleWidth(at: 10)))
        view.addCornerRadius(at: ScaleWidth(at: 6))
        let custom = GroupDeleteActionView(frame: .zero)
        
        for button in view.subviews {
            
            if button.description.contains("UISwipeActionStandardButton") {
                button.backgroundColor = .groupEditCellDeleteActionColor
                button.isHidden = true
                view.addSubview(custom)
                custom.addCornerRadius(at: 6)
                custom.backgroundColor = .groupEditCellDeleteActionColor
                custom.snp.makeConstraints {
                    
                    $0.edges.equalTo(button)
                }
            }
        }
    }
    
    private func searchDeleteView() {
        
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

class GroupDeleteActionView: UIView {
    
    private let image: UIImageView = .init(image: .noSMSgroupMenuRemoveAction)
    private let label: UILabel = {
       
        let label = UILabel()
        label.setText("删除")
            .setFont(.pingFangMediumFont(size: 12))
            .setTextColor(.white)
            .setTextAlignment(.center)
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(image)
        addSubview(label)
        
        image.snp.makeConstraints {
            
            $0.top.equalTo(ScaleWidth(at: 2))
            $0.left.equalTo(ScaleWidth(at: 9))
            $0.size.equalTo(ScaleWidth(at: 40))
        }
        
        label.snp.makeConstraints {
            
            $0.centerX.equalTo(image)
            $0.bottom.equalTo(ScaleWidth(at: -7))
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}



extension UIViewController {
    
    static var groupViewControllver: UIViewController {
        
        return GroupViewController(viewModel: GroupVCViewModel())
    }
}

extension UIImage {

    /// This method creates an image of a view
    convenience init?(view: UIView) {

        // Based on https://stackoverflow.com/a/41288197/1118398
        let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
        let image = renderer.image { rendererContext in
            view.layer.render(in: rendererContext.cgContext)
        }

        if let cgImage = image.cgImage {
            self.init(cgImage: cgImage, scale: UIScreen.main.scale, orientation: .up)
        } else {
            return nil
        }
    }
}
