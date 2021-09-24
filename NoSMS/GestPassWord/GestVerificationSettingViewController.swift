
import RxSwift
import RxCocoa
import JXPatternLock

class GestVerificationSettingViewController: BaseViewControllerNoGeneric {
    
    private let gestVerificationVC: GestVerificationViewController
    private let viewModel: GestVerificationSettingViewControllerViewModelType
    private let pathView: PatternLockPathView = .init(config: PasswordPathConfig())
    private let rightNavigationItem: UIBarButtonItem = .init(title: "重设", style: .done, target: nil, action: nil)
    
    init(viewModel: GestVerificationSettingViewControllerViewModelType) {
        
        self.gestVerificationVC = .init(viewModel: viewModel)
        self.viewModel = viewModel
        super.init(baseVCViewModel: viewModel)
        
        addChild(gestVerificationVC)
        view.addSubview(gestVerificationVC.view)
        view.addSubview(pathView)
        
        pathView.snp.makeConstraints {
            
            $0.size.equalTo(ScaleWidth(at: 71))
            $0.top.equalTo(ScaleWidth(at: 76.5))
            $0.centerX.equalToSuperview()
        }
        
        gestVerificationVC.view.snp.makeConstraints {
            
            $0.top.equalTo(ScaleWidth(at: 76.5))
            $0.right.left.bottom.equalToSuperview()
        }
                
        rightNavigationItem.rx
            .tap
            .bind(onNext: viewModel.reset)
            .disposed(by: disposedBag)

        viewModel.pathViewGridMatrix
            .bind(onNext: pathView.addGrid(at:))
            .disposed(by: disposedBag)
        
        viewModel.resetButtonIsHidden
            .subscribe(onNext: { [weak self] isHidden in
             
                guard let self = self else { return }
                if isHidden {
                    
                    self.navigationItem.rightBarButtonItem = nil
                } else {
                    
                    self.navigationItem.rightBarButtonItem = self.rightNavigationItem
                }
            }).disposed(by: disposedBag)
        
        viewModel.resetPathViewSignal
            .bind(onNext: pathView.reset)
            .disposed(by: disposedBag)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
