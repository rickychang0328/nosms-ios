
import UIKit
import RxSwift
import RxCocoa
import AVFoundation

enum TokenListViewModelEvent {
    
    case reloadData
    case error(Error)
}

protocol TokenListVCViewModelProtocol: BaseTableViewVCViewModelProtocol {
    
    var eventResult: BehaviorSubject<TokenListViewModelEvent> { get }
    
    func deleteToken(index: Int)
    func selectItem(index: Int) -> Observable<String>
    func swapToken(beforeIndex: Int, afterIndex: Int)
}

protocol TokenListSectionItemProtocol: BaseTableViewSectionItemsProtocol {
    
    var rowItems: [BaseTableViewCellViewModelProtocol] { get set }
}

class TokenListSectionItem: TokenListSectionItemProtocol {
    
    var sectionHeaderViewModel: BaseTableViewSectionHeaderFooterViewModelProtocol?
    
    var sectionFooterViewModel: BaseTableViewSectionHeaderFooterViewModelProtocol?
    
    var numberOfRow: Int {
        
        return rowItems.count
    }
    
    var rowItems: [BaseTableViewCellViewModelProtocol] = []
    
    subscript(index: Int) -> BaseTableViewCellViewModelProtocol {
        
        return rowItems[index]
    }
}

class TokenListVCViewModel: BaseVCViewModel, TokenListVCViewModelProtocol {
  
    let eventResult: BehaviorSubject<TokenListViewModelEvent> = .init(value: .reloadData)

    var tableViewStyle: UITableView.Style {
        
        return .grouped
    }
    
    var cellViewModels: [BaseTableViewSectionItemsProtocol] {
        
        return [sectionItems]
    }
    
    private let sectionItems: TokenListSectionItemProtocol
    
    private let tokenStore: TokenStoreProtocol
            
    init(navigationItemViewModel: BaseNavigaitonItemProtocol = BaseNavigaitonItem(title: .init(value: "TokenList")),
         tokenStore: TokenStoreProtocol = KeychainTokenStore.shared,
         backgroundColor: UIColor = .clear,
         sectionItems: TokenListSectionItemProtocol = TokenListSectionItem()) {
        
        self.tokenStore = tokenStore
        self.sectionItems = sectionItems
        super.init(navigationItem: navigationItemViewModel, backgroundColor: backgroundColor)
        
        tokenStore.persistentTokensBehavior
            .map( {
                $0.map({
                    TableViewCellViewModelFactory.getCellViewModel(type: .tokenList($0))
                })
            })
            .subscribe(onNext: { [weak self] viewModels in
                guard let self = self else { return }
                self.sectionItems.rowItems = viewModels
                self.eventResult.onNext(.reloadData)
            })
            .disposed(by: disposedBag)
    }
    
    func deleteToken(index: Int) {
            
        do {
            try tokenStore.deleteToken(index: index)
        } catch {
            
            eventResult.onNext(.error(error))
        }
    }
    
    func swapToken(beforeIndex: Int, afterIndex: Int) {
        
        do {
            try tokenStore.moveTokenFromIndex(beforeIndex, toIndex: afterIndex)
        } catch {
            
            eventResult.onNext(.error(error))
        }
    }
    
    func selectItem(index: Int) -> Observable<String> {

        let observer: Observable<String> = .create { anyObserver -> Disposable in
            
            let a = self.tokenStore.persistentTokensBehavior
                .map({$0[index]})
                .flatMapLatest({$0.password})
                .subscribe(onNext: { string in

                    UIPasteboard.general.string = string
                    
                    anyObserver.onNext(string)
                    anyObserver.onCompleted()
                }, onError: { error in
                    
                    anyObserver.onError(error)
                })
            return Disposables.create { a.dispose() }
        }
        
        return observer
    }
}

class TokenListViewController<VCViewModel: TokenListVCViewModelProtocol>: BaseTableViewController<VCViewModel> {
    
    private var lifeCycleDisposeBag: DisposeBag = .init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let barButton = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)
        
        barButton.rx.tap.subscribe { [weak self] _ in
            
            guard let self = self else { return }
            self.showAddTokenAlert()
            
        }.disposed(by: disposedBag)
        
        let editTableViewBarItem = UIBarButtonItem(barButtonSystemItem: .edit, target: nil, action: nil)
        
        editTableViewBarItem.rx.tap.subscribe { [weak self] _ in
            guard let self = self else { return }
            
            self.tableView.setEditing(!self.tableView.isEditing, animated: true)
        }.disposed(by: disposedBag)
        
        navigationItem.rightBarButtonItems = [barButton, editTableViewBarItem]
        
        viewModel.eventResult.subscribe { [weak self] _ in
            
            self?.tableView.reloadData()
        }.disposed(by: disposedBag)
        
        tableView.rx.itemMoved
            .map({($0.sourceIndex.row, $0.destinationIndex.row)})
            .subscribe(onNext: self.viewModel.swapToken)
            .disposed(by: disposedBag)
        
        tableView.rx.itemDeleted.subscribe(onNext: { [weak self] indexPath in

            self?.showDeleteAlert(index: indexPath.row)
        }).disposed(by: disposedBag)

        tableView.rx.itemSelected
            .map({ $0.row })
            .flatMapLatest(self.viewModel.selectItem)
            .subscribe(onNext: { [weak self] _ in
            
                self?.showErrorAlert(title: "成功複製")
            }, onError: { [weak self] error in
            
                self?.showErrorAlert(title: "複製失敗")
            }, onDisposed: { [weak self] in
                    
                self?.showErrorAlert(title: "Disposed")
            }).disposed(by: disposedBag)
        
        tableView.backgroundColor = .gray
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        viewModel.intoAppPastedAction.subscribe(onNext: { [weak self] pastedString in
                   
            self?.showPastedStringAlert(pastedString: pastedString)
        }).disposed(by: lifeCycleDisposeBag)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        lifeCycleDisposeBag = .init()
    }
   
    private func showPastedStringAlert(pastedString: String) {
        
        let alertVC = UIAlertController(title: "是否貼上此URL", message: pastedString, preferredStyle: .alert)
        
        let goPastedAlertAction = UIAlertAction(title: "去貼上", style: .default) { [weak self] _ in
            
            guard let self = self else { return }
            self.showKeyinTokenVC(string: pastedString)
        }
      
        let cancelAlertAction = UIAlertAction(title: "取消", style: .cancel) { [weak alertVC] _ in
            
            alertVC?.dismiss(animated: true, completion: nil)
        }
        
        alertVC.addAction(goPastedAlertAction)
        alertVC.addAction(cancelAlertAction)
        
        present(alertVC, animated: true, completion: nil)
    }
    
    private func showAddTokenAlert() {
        
        let alertVC = UIAlertController(title: "選擇方法", message: nil, preferredStyle: .actionSheet)
        let goPhotoeAlertAction = UIAlertAction(title: "去相簿", style: .default) { [weak self] _ in
            
            guard let self = self else { return }
            self.showPhoto()
        }
        
        let goTokenScannerAlertAction = UIAlertAction(title: "去掃描", style: .default) { [weak self] _ in
            
            guard let self = self else { return }
            self.showTokenScannerVC()
        }
        
        let goKeyinAddTokenAlertAction = UIAlertAction(title: "手動加入", style: .default) { [weak self] _ in
            
            guard let self = self else { return }
            self.showKeyinTokenVC()
        }
        
        let cancelAlertAction = UIAlertAction(title: "取消", style: .cancel) { [weak alertVC] _ in
            
            alertVC?.dismiss(animated: true, completion: nil)
        }
        
        alertVC.addAction(goPhotoeAlertAction)
        alertVC.addAction(goTokenScannerAlertAction)
        alertVC.addAction(goKeyinAddTokenAlertAction)
        alertVC.addAction(cancelAlertAction)
        
        present(alertVC, animated: true, completion: nil)
    }
    
    private func showKeyinTokenVC(string: String? = nil) {
        
        let nextVC = JoinManuallyTOTPTypeViewController(viewModel: JoinManuallyVCViewModel(pastedString: string))
        
        navigationController?.pushViewController(nextVC, animated: true)
    }
    
    private func showTokenScannerVC() {
        
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        if status == .restricted || status == .denied {
            
            
        } else {
            
            let nextVC = TokenScannerViewController(viewModel: TokenScannerViewModel())
                 
            navigationController?.pushViewController(nextVC, animated: true)
        }
    }
    
    private func showPhoto() {
        
        let photoVC = PhotoCheckViewController(viewModel: PhotoCheckVCViewModel())
        present(photoVC, animated: true, completion: nil)
    }
    
    private func showDeleteAlert(index: Int) {
        
        let alertVC = UIAlertController(title: "真的要刪除嗎", message: "刪除後無法復原", preferredStyle: .alert)
        let cancelAlertAction = UIAlertAction(title: "取消", style: .cancel) { [weak alertVC] _ in
            alertVC?.dismiss(animated: true, completion: nil)
        }
        let deleteAlertAction = UIAlertAction(title: "確認", style: .default) { [weak self] _ in
            
            self?.viewModel.deleteToken(index: index)
        }
        alertVC.addAction(cancelAlertAction)
        alertVC.addAction(deleteAlertAction)
        present(alertVC, animated: true, completion: nil)
    }
}

extension Reactive where Base: UIAlertController {
    
    static func creatAlertVC()  {
        
    }
}

extension Reactive where Base: UITableView {
    
    var isEditing: Binder<Bool> {
        
        return Binder<Bool>(self.base) { view, isEdit in
            
            view.isEditing = isEdit
        }
    }
}
