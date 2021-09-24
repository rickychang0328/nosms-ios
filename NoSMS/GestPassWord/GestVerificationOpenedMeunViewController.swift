
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
            
            self.goChangGestPassword()
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
    
    func goChangGestPassword() {
        
        let viewModel = GestVerificationSettingViewControllerViewModel { coordinator in
            
            switch coordinator {
            
            case .settingPasswordDone:
                self.viewModel.popToBeforeVC()
                NoSMSHUD.showToast(title: "手势解锁已开启")
            }
        }
        
        let vc = GestVerificationSettingViewController(viewModel: viewModel)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func goClosePassword() {
        
        let viewModel = GestVerificationViewControllerViewModel { coordinator in
            switch coordinator {
            
            case .verifySuccess:
                self.viewModel.closeGestPassword()
                self.viewModel.popToBeforeVC()
                NoSMSHUD.showToast(title: "手势解锁已关闭")
            }
        }
        let vc = GestVerificationViewController(viewModel: viewModel)
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
