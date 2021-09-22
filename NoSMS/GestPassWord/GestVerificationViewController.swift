
import UIKit
import RxCocoa
import RxSwift
import JXPatternLock

class GestVerificationViewController: BaseViewControllerNoGeneric {
    
    private let viewModel: GestVerificationViewControllerViewModelType
    
    private let titleLabel: UILabel = {
        
        let label = UILabel()
        label.font = .pingFangRegularFont(size: 15)
        return label
    }()
    
    private let lockView: PatternLockView = {
        
        let lockView = PatternLockView(config: PasswordConfig())
        return lockView
    }()
    
    init(viewModel: GestVerificationViewControllerViewModelType) {
        
        self.viewModel = viewModel
        super.init(baseVCViewModel: viewModel)
        
        lockView.delegate = self
        
        view.addSubview(titleLabel)
        view.addSubview(lockView)
        
        titleLabel.snp.makeConstraints {
            
            $0.centerX.equalToSuperview()
            $0.topMargin.equalTo(ScaleWidth(at: 100))
        }
        
        let lockWidth = ScaleWidth(at: 375) - 90
        
        lockView.snp.makeConstraints {
            $0.width.height.equalTo(lockWidth)
            $0.centerX.equalToSuperview()
            $0.top.equalTo(titleLabel.snp.bottom).offset(ScaleWidth(at: 50))
        }
        
        viewModel.title
            .bind(to: titleLabel.rx.text)
            .disposed(by: disposedBag)
        viewModel.titleColor
            .bind(to: titleLabel.rx.textColor)
            .disposed(by: disposedBag)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension GestVerificationViewController: PatternLockViewDelegate {
    
    func lockView(_ lockView: PatternLockView, didConnectedGrid grid: PatternLockGrid) {
        
        viewModel.didConnectGrid(lockGrid: grid)
    }
    
    func lockViewShouldShowErrorBeforeConnectCompleted(_ lockView: PatternLockView) -> Bool {
        
        return viewModel.shouldShowErrorBeforeConnectCompleted()
    }
    
    func lockViewDidConnectCompleted(_ lockView: PatternLockView) {
        
        viewModel.didConnectCompleted()
    }
}
