
import RxCocoa
import RxSwift

class GestVerificationOpenedMeunViewController: BaseTableViewControllerNoGeneric {
    
    private let viewModel: GestVerificationOpenedMeunViewControllerViewModelType
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        return ScaleWidth(at: 15)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let cellType = viewModel.cellType[indexPath.row]
        switch cellType {
        
        case .changeGestPassword:
            
            self.goChangeGestPassword()
        case .closePassword:
            
            self.goClosePassword()
        }
    }
    
    init(viewModel: GestVerificationOpenedMeunViewControllerViewModelType) {
        self.viewModel = viewModel
        super.init(baseTableViewModel: viewModel)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func pushGestVerificationViewController(navigationTitle: String, verifySuccessCoordinator: @escaping () -> Void) {
        
        let viewModel = GestVerificationViewControllerViewModel(navigationTitle: navigationTitle, title: "请输入原手势密码") { coordinator in
            switch coordinator {
            
            case .verifySuccess:
                
                verifySuccessCoordinator()
            }
        }
        let vc = GestVerificationViewController(viewModel: viewModel)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func pushGestVerificationSettingViewController(navigationTitle: String, animated: Bool, settingPasswordDoneCoordinator: @escaping () -> Void) {
        
        let viewModel = GestVerificationSettingViewControllerViewModel(navigationTitle: navigationTitle) { coordinator in
                    
            switch coordinator {
            
            case .settingPasswordDone:
                settingPasswordDoneCoordinator()
            }
        }
        let vc = GestVerificationSettingViewController(viewModel: viewModel)
        self.navigationController?.pushViewController(vc, animated: animated)
    }
    
    func goChangeGestPassword() {
        
        let navigationTitle = "验证手势密码"
        pushGestVerificationViewController(navigationTitle: navigationTitle) {
            
            self.navigationController?.popViewController(animated: false)
            self.pushGestVerificationSettingViewController(navigationTitle: navigationTitle, animated: false, settingPasswordDoneCoordinator: {
                
                self.viewModel.popToBeforeVC()
                NoSMSHUD.showToast(title: "手势密码已修改")
            })
        }
    }
    
    func goClosePassword() {
        
        pushGestVerificationViewController(navigationTitle: "验证手势密码", verifySuccessCoordinator: {
            
            self.viewModel.closeGestPassword()
            self.viewModel.popToBeforeVC()
            NoSMSHUD.showToast(title: "手势解锁已关闭")
        })
    }
}
