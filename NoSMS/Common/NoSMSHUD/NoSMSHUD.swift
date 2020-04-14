
import UIKit
import RxCocoa
import RxSwift

class NoSMSAlertView: UIView {
    
    let cancelButton: UIButton = {
        
        let button = UIButton()
        button.setBackgroundColor(.alertCancelButtonBackgroundColor)
        button.setTitleColor(.alertCancelButtonTextColor, for: .normal)
        button.titleLabel?.font = .pingFangMediumFont(size: 14)
        button.addCornerRadius(at: ScaleWidth(at: 4))
        return button
    }()
    
    let confirmButton: UIButton = {
        
        let button = UIButton()
        button.setBackgroundColor(.alertActionButtonBackgroundColor)
        button.setTitleColor(.alertActionButtonTextColor, for: .normal)
        button.titleLabel?.font = .pingFangMediumFont(size: 14)
        button.addCornerRadius(at: ScaleWidth(at: 4))
        return button
    }()
    
    let titleLabel: UILabel = {
        
        let label = UILabel()
        label.setFont(.pingFangSemiBoldFont(size: 15))
            .setTextColor(.alertTextColor)
            .setNumberOfLine(0)
            .setTextAlignment(.left)
        return label
    }()
    
    let messageLabel: UILabel = {
           
        let label = UILabel()
        label.setFont(.pingFangMediumFont(size: 14))
            .setTextColor(.alertTextColor)
            .setNumberOfLine(0)
            .setTextAlignment(.left)
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .alertsBackgroundColor
        addSubview(titleLabel)
        addSubview(messageLabel)
        addSubview(cancelButton)
        addSubview(confirmButton)
        titleLabel.preferredMaxLayoutWidth = ScaleWidth(at: 235)
        titleLabel.snp.makeConstraints {
            
            $0.top.equalTo(ScaleWidth(at: 20))
            $0.centerX.equalToSuperview()
        }
        
        messageLabel.preferredMaxLayoutWidth = ScaleWidth(at: 240)
        messageLabel.snp.makeConstraints {
            
            $0.top.equalTo(titleLabel.snp.bottom).offset(ScaleWidth(at: 6))
            $0.centerX.equalToSuperview()
        }
        
        cancelButton.snp.makeConstraints {
            
            $0.top.equalTo(messageLabel.snp.bottom).offset(ScaleWidth(at: 20))
            $0.left.equalTo(ScaleWidth(at: 12))
            $0.bottom.equalTo(ScaleWidth(at: -12))
            $0.height.equalTo(ScaleWidth(at: 37))
            $0.width.equalTo(ScaleWidth(at: 120))
        }
        
        confirmButton.snp.makeConstraints {
            
            $0.top.size.bottom.equalTo(cancelButton)
            $0.right.equalTo(ScaleWidth(at: -12))
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class NoSMSStreetAlertViewController: UIViewController {
    
    let cancelButton: UIButton = {
        
        let button = UIButton()
        button.setBackgroundColor(.clear)
        button.setTitleColor(.alertCancelButtonTextColor, for: .normal)
        button.titleLabel?.font = .pingFangMediumFont(size: 14)
        button.addCornerRadius(at: ScaleWidth(at: 4))
        return button
    }()
    
    let confirmButton: UIButton = {
        
        let button = UIButton()
        button.setBackgroundColor(.clear)
        button.setTitleColor(.alertStreetActionButtonTextColor, for: .normal)
        button.titleLabel?.font = .pingFangMediumFont(size: 14)
        button.addCornerRadius(at: ScaleWidth(at: 4))
        return button
    }()
    
    let titleLabel: UILabel = {
        
        let label = UILabel()
        label.setFont(.pingFangSemiBoldFont(size: 15))
            .setTextColor(.alertTextColor)
            .setNumberOfLine(0)
            .setTextAlignment(.left)
        return label
    }()

    private let downCancelView: UIView = {
        
        let view = UIView()
        //TODO:
        view.setBackgroundColor(.alertStreetCancelButtonBackGroundColor)
            .addCornerRadius(at: ScaleWidth(at: 6))
        return view
    }()
    
    private let upView: UIView = {
        
        let view = UIView()
        //TODO:
        view.addCornerRadius(at: ScaleWidth(at: 6))
            .setBackgroundColor(.alertsBackgroundColor)
        return view
    }()
    
    private let disposeBag: DisposeBag = .init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .clear
        view.addSubview(downCancelView)
        view.addSubview(upView)
        upView.addSubview(titleLabel)
        downCancelView.addSubview(cancelButton)
        upView.addSubview(confirmButton)
        titleLabel.preferredMaxLayoutWidth = ScaleWidth(at: 240)
        
        let tapGest = UITapGestureRecognizer()
        view.addGestureRecognizer(tapGest)
        tapGest.rx.event.subscribe(onNext: { [weak self] _ in
            
            self?.dismiss(animated: true, completion: nil)
            }).disposed(by: disposeBag)
        
        downCancelView.snp.makeConstraints {
            
            $0.left.right.equalToSuperview().inset(ScaleWidth(at: 15))
            $0.bottom.equalTo(ScaleWidth(at: -34))
            $0.height.equalTo(ScaleWidth(at: 42))
        }
        
        upView.snp.makeConstraints {
            
            $0.bottom.equalTo(downCancelView.snp.top).offset(ScaleWidth(at: -15))
            $0.left.right.equalTo(downCancelView)
        }
        
        titleLabel.snp.makeConstraints {
            
            $0.top.equalTo(ScaleWidth(at: 20))
            $0.centerX.equalToSuperview()
        }
        
        let lineView = UIView()
        
        upView.addSubview(lineView)
        
        //TODO:
        lineView.setBackgroundColor(.alertStreetUnderLineColor)
        
        lineView.snp.makeConstraints {
            
            $0.left.right.equalToSuperview()
            $0.top.equalTo(titleLabel.snp.bottom).offset(ScaleWidth(at: 20))
            $0.height.equalTo(0.5)
        }
        
        cancelButton.snp.makeConstraints {
            
            $0.edges.equalToSuperview()
        }
        
        confirmButton.snp.makeConstraints {
            
            $0.bottom.equalToSuperview().offset(ScaleWidth(at: -10))
            $0.left.right.equalToSuperview()
            $0.top.equalTo(lineView.snp.bottom).offset(ScaleWidth(at: 10))
        }
    }
    
    func showAlertSetting(title: String? = nil,
                          confirmTitle: String = "ok",
                          cancelTitle: String = "取消",
                          confirmAction: (() -> Void)? = nil,
                          cancelAction: (() -> Void)? = nil) {
        
        
        titleLabel.text = title
        cancelButton.setTitle(cancelTitle, for: .normal)
        confirmButton.setTitle(confirmTitle, for: .normal)
        cancelButton.rx.tap.subscribe(onNext: { [weak self] in
            
            guard let self = self else { return }
            self.dismiss(animated: false, completion: cancelAction)
        }).disposed(by: disposeBag)
        
        confirmButton.rx.tap.subscribe(onNext: { [weak self] in
        
            guard let self = self else { return }
            self.dismiss(animated: false, completion: confirmAction)
        }).disposed(by: disposeBag)
    }
}

class NoSMSAlertViewController: UIViewController {
    
    let alertView: NoSMSAlertView = {
        
        let view = NoSMSAlertView(frame: .zero)
        view.setBackgroundColor(.alertsBackgroundColor)
            .addCornerRadius(at: ScaleWidth(at: 6))
        return view
    }()
    
    private let disposeBag: DisposeBag = .init()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        view.addSubview(alertView)
        
        alertView.snp.makeConstraints {
            
            $0.center.equalToSuperview()
            $0.width.equalTo(ScaleWidth(at: 276))
            $0.top.equalTo(40).priorityLow()
            $0.bottom.equalTo(-40).priorityLow()
        }
    }
    
    func showAlertSetting(title: String? = nil,
                          message: String? = nil,
                          confirmTitle: String = "ok",
                          cancelTitle: String = "取消",
                          confirmAction: (() -> Void)? = nil,
                          cancelAction: (() -> Void)? = nil) {
        
        
        alertView.titleLabel.text = title
        alertView.messageLabel.text = message
        alertView.cancelButton.setTitle(cancelTitle, for: .normal)
        alertView.confirmButton.setTitle(confirmTitle, for: .normal)
        alertView.cancelButton.rx.tap.subscribe(onNext: { [weak self] in
            
            guard let self = self else { return }
            self.dismiss(animated: false, completion: cancelAction)
        }).disposed(by: disposeBag)
        
        alertView.confirmButton.rx.tap.subscribe(onNext: { [weak self] in
        
            guard let self = self else { return }
            self.dismiss(animated: false, completion: confirmAction)
        }).disposed(by: disposeBag)
    }
}

class NoSMSHUD {
    
    static var toastView: UIView {
        
        let view = UIView()
        view.setBackgroundColor(.toastBackgroundColor)
            .addCornerRadius(at: ScaleWidth(at: 6))
        return view
    }
    
    static var toastLabel: UILabel {
       
        let label = UILabel()
        label.setFont(.pingFangSemiBoldFont(size: 15))
            .setTextColor(.toastTextColor)
            .setNumberOfLine(20)
            .setTextAlignment(.center)
        label.preferredMaxLayoutWidth = ScaleWidth(at: 240)
        return label
    }
    
    static var toastLastView: UIView?
    
    static var toastLastLabel: UIView?

    static func showToast(title: String,
                          contentView: UIView? = nil,
                          toastSecond: Double = 1,
                          completion: (() -> Void)? = nil) {
        
        dismiss()
        let displayView: UIView
        
        if let contentView = contentView {
            
            displayView = contentView
        } else {
            
            var vc = UIApplication.shared.keyWindow!.rootViewController!
            
            while vc.presentedViewController != nil {
                
                vc = vc.presentedViewController!
            }
            
            displayView = vc.view
        }
        
        let toastView = self.toastView
        let toastLabel = self.toastLabel
        toastLastView = toastView
        toastLastLabel = toastLabel
        
        displayView.addSubview(toastView)
        displayView.addSubview(toastLabel)
        toastLabel.setText(title)
        
        toastLabel.snp.makeConstraints {
                  
            $0.center.equalToSuperview()
        }
        toastView.snp.makeConstraints {
            
            $0.top.equalTo(toastLabel).offset(ScaleWidth(at: -15))
            $0.bottom.equalTo(toastLabel).offset(ScaleWidth(at: 15))
            $0.left.equalTo(toastLabel).offset(ScaleWidth(at: -30))
            $0.right.equalTo(toastLabel).offset(ScaleWidth(at: 30))
        }
    
        DispatchQueue.main.asyncAfter(deadline: .now() + toastSecond) {
            
            dismiss(toastView: toastView, toastLabel: toastLabel, completion: completion)
        }
    }
    static func dismiss(toastView: UIView? = toastLastView, toastLabel: UIView? = toastLastLabel, completion: (() -> Void)? = nil) {
        
        if toastLabel?.superview != nil {
           
            toastLabel?.removeFromSuperview()
        }
        
        if toastView?.superview != nil {
            
            toastView?.removeFromSuperview()
        }
        completion?()
    }
}

extension UIViewController {
    
    func showAlert(title: String? = nil,
                   message: String? = nil,
                   confirmTitle: String = "确认",
                   cancelTitle: String = "取消",
                   confirmAction: (() -> Void)? = nil,
                   cancelAction: (() -> Void)? = nil) {
        
        
        let vc = NoSMSAlertViewController()
        vc.showAlertSetting(title: title, message: message, confirmTitle: confirmTitle,
                            cancelTitle: cancelTitle, confirmAction: confirmAction, cancelAction: cancelAction)
        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
        present(vc, animated: true, completion: nil)
    }
    
    func showStreetDeleteAlert(title: String? = nil,
                               confirmTitle: String = "删除",
                               cancelTitle: String = "取消",
                               confirmAction: (() -> Void)? = nil,
                               cancelAction: (() -> Void)? = nil) {
        
        let vc = NoSMSStreetAlertViewController()
        vc.showAlertSetting(title: title,
                            confirmTitle: confirmTitle,
                            cancelTitle: cancelTitle,
                            confirmAction: confirmAction,
                            cancelAction: cancelAction)
        vc.modalPresentationStyle = .overCurrentContext
        vc.modalTransitionStyle = .crossDissolve
        present(vc, animated: true, completion: nil)
    }
}
