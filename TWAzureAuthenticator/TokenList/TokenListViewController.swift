//
//  TokenListViewController.swift
//  TWAzureAuthenticator
//
//  Created by 誠帷數位科技 on 2019/11/25.
//

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
//                let token = try self.tokenStore.persistentTokensBehavior.value()[index]
//                let password = try token.password.value()
         
            return Disposables.create {
                a.dispose() }
        }
        
        
//        let result = self.tokenStore.persistentTokensBehavior.map({$0[index]}).flatMapLatest({$0.password}).asObservable()
        return observer
    }
}

class TokenListViewController<VCViewModel: TokenListVCViewModelProtocol>: BaseTableViewController<VCViewModel> {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let barButton = UIBarButtonItem(barButtonSystemItem: .add, target: nil, action: nil)
        
        barButton.rx.tap.subscribe { [weak self] _ in
            
            guard let self = self else { return }
            self.showAddTokenAlert()
            
        }.disposed(by: disposedBag)
        
//        let editTableViewBarItem = UIBarButtonItem(barButtonSystemItem: .edit, target: nil, action: nil)
        
//        editTableViewBarItem.rx.tap
        
        navigationItem.rightBarButtonItem = barButton
        
        viewModel.eventResult.subscribe { [weak self] _ in
            
            self?.tableView.reloadData()
        }.disposed(by: disposedBag)
        
        
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
        
        let cancelAlertAction = UIAlertAction(title: "取消", style: .cancel) { [weak alertVC] _ in
            
            alertVC?.dismiss(animated: true, completion: nil)
        }
        
        alertVC.addAction(goPhotoeAlertAction)
        alertVC.addAction(goTokenScannerAlertAction)
        alertVC.addAction(cancelAlertAction)
        
        present(alertVC, animated: true, completion: nil)
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
    
    var isEdit: Binder<Bool> {
        
        return Binder<Bool>(self.base) { view, isEdit in
            
            view.isEditing = isEdit
        }
    }
    
//    func isEditBinding() ->
}
