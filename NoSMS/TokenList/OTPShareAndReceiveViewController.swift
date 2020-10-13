//
//  OTPShareAndReceiveViewController.swift
//  NoSMS
//
//  Created by Andy LI on 2020/10/8.
//

import UIKit
import RxSwift
import RxCocoa
import LocalAuthentication
import BiometricAuthentication

class OTPShareAndReceiveViewController: UIViewController {
    
    var disposedBag: DisposeBag = .init()
    
    private lazy var exportOTPButton: UIButton = {
        
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.backgroundColor = .white
        button.frame = CGRect(x: 0, y: 0, width: 345, height: 42)
        button.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            if !BioMetricAuthenticator.shared.faceIDAvailable() && !AuthIDStatusManager.touchIDAvailable() {
                self.showFaceIDAlert(title: "",
                               message: "您的设备尚未开启指纹识别",
                               confirmTitle: "设置",
                               cancelTitle: "取消", confirmAction: {
                                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                                    return
                                }
                                
                                if UIApplication.shared.canOpenURL(settingsUrl) {
                                    UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                                        print("Settings opened: \(success)")
                                    })
                                }
                                
                                
                }, cancelAction: {
                    
                })
                
                return
            }
            let context = LAContext()
            context.localizedCancelTitle = "Cancel"
            var error: NSError?
            if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
                
                let reason = "Log in to your account"
                context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { (success, error) in
                    if success {
                        DispatchQueue.main.async { [unowned self] in
                            let newViewController = ShareOTPViewController(viewModel: TokenListVCViewModel())
                            self.navigationController?.pushViewController(newViewController, animated: true)
                        }
                    } else {
                        DispatchQueue.main.async { [unowned self] in
                        }
                    }
                }
            } else {
                
            }
            
        }).disposed(by: disposedBag)
        return button
    }()
    
    private lazy var receiveOTPButton: UIButton = {
        
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.backgroundColor = .white
        button.frame = CGRect(x: 0, y: 0, width: 345, height: 42)
        button.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            
        }).disposed(by: disposedBag)
        return button
    }()
    
    private lazy var shareOTPRecordButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.backgroundColor = .clear
        button.titleLabel?.font = UIFont(name: TFontName.PingFangFontMedium.rawValue , size: 15)
        button.setTitle("近期分享记录", for: .normal)
        button.setTitleColor(UIColor.getColor(red: 98, green: 112, blue: 255, alpha: 1), for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 345, height: 42)
        button.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            
        }).disposed(by: disposedBag)
        return button
    }()
    private lazy var topHint: UILabel = {
        
        let label = UILabel()
        label.text = "您可以将验证码分享到已安装MustAuth的新设备中"
        label.font = UIFont(name: TFontName.PingFangFontMedium.rawValue , size: 15)
        label.textAlignment = .center
        label.textColor = UIColor.getColor(red: 102, green: 102, blue: 102, alpha: 1)
        label.frame = CGRect(x: 0, y: 0, width: 345, height: 42)
        return label
    }()
    
    private lazy var exportButtonLabel: UILabel = {
        let label = UILabel()
        label.text = "导出验证码"
        label.font = UIFont(name: TFontName.PingFangFontMedium.rawValue , size: 16)
        label.textAlignment = .left
        label.textColor = UIColor.getColor(red: 51, green: 51, blue: 51, alpha: 1)
        label.frame = CGRect(x: 0, y: 0, width: 345, height: 42)
        return label
    }()
    
    private lazy var receiveButtonLabel: UILabel = {
        let label = UILabel()
        label.text = "导入验证码"
        label.font = UIFont(name: TFontName.PingFangFontMedium.rawValue , size: 16)
        label.textAlignment = .left
        label.textColor = UIColor.getColor(red: 51, green: 51, blue: 51, alpha: 1)
        label.frame = CGRect(x: 0, y: 0, width: 345, height: 42)
        return label
    }()
    
    private lazy var exportButtonHint: UILabel = {
        let label = UILabel()
        label.text = "选择欲导出的验证码，并创建您的二维码"
        label.font = UIFont(name: TFontName.PingFangFontMedium.rawValue , size: 12)
        label.textAlignment = .left
        label.textColor = UIColor.getColor(red: 136, green: 136, blue: 138, alpha: 1)
        label.frame = CGRect(x: 0, y: 0, width: 345, height: 42)
        return label
    }()
    
    private lazy var receiveButtonHint: UILabel = {
        let label = UILabel()
        label.text = "选择欲导出的验证码，并创建您的二维码"
        label.font = UIFont(name: TFontName.PingFangFontMedium.rawValue , size: 12)
        label.textAlignment = .left
        label.textColor = UIColor.getColor(red: 136, green: 136, blue: 138, alpha: 1)
        label.frame = CGRect(x: 0, y: 0, width: 345, height: 42)
        return label
    }()
    
    private lazy var shareOTPImageView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(named: "NOSMS_sharecodeLightIcon")
        view.backgroundColor = UIColor.white
        return view
    }()
    
    private lazy var shareOTPRecordImageView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(named: "NoSMS_historyIcon")
        view.backgroundColor = UIColor.white
        return view
    }()
    
    private lazy var exportButtonImageView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = UIColor.black
        return view
    }()
    
    private lazy var receiveButtonImageView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = UIColor.black
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setLayOut()
    }
    
    private func setLayOut() {
        self.navigationItem.title = "验证码分享"
        self.view.backgroundColor = .tokenListBackgroundColor
        view.addSubview(shareOTPImageView)
        view.addSubview(topHint)
        view.addSubview(exportOTPButton)
        view.addSubview(receiveOTPButton)
        view.addSubview(exportButtonLabel)
        view.addSubview(receiveButtonLabel)
        view.addSubview(exportButtonHint)
        view.addSubview(receiveButtonHint)
        view.addSubview(exportButtonImageView)
        view.addSubview(receiveButtonImageView)
        view.addSubview(shareOTPRecordImageView)
        view.addSubview(shareOTPRecordButton)
        
        shareOTPImageView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(ScaleWidth(at: 45.5))
            $0.height.equalTo(ScaleWidth(at: 71))
            $0.width.equalTo(ScaleWidth(at: 121.5))
            $0.centerX.equalToSuperview()
        }
        
        topHint.snp.makeConstraints {
            $0.top.equalTo(ScaleWidth(at: 163.5))
            $0.left.equalToSuperview().offset(ScaleWidth(at: 18))
            $0.right.equalToSuperview().offset(ScaleWidth(at: -18))
            $0.height.equalTo(ScaleWidth(at: 80))
            $0.centerX.equalToSuperview()
        }
        
        exportOTPButton.snp.makeConstraints {
            $0.top.equalTo(topHint.snp.bottom).offset(ScaleWidth(at: 30))
            $0.height.equalTo(ScaleWidth(at: 80))
            $0.left.equalToSuperview().offset(ScaleWidth(at: 15))
            $0.right.equalToSuperview().offset(ScaleWidth(at: -15))
            $0.centerX.equalToSuperview()
        }
        
        receiveOTPButton.snp.makeConstraints {
            $0.top.equalTo(exportOTPButton.snp.bottom).offset( ScaleWidth(at: 12.5))
            $0.height.equalTo(ScaleWidth(at: 80))
            $0.left.equalToSuperview().offset(ScaleWidth(at: 15))
            $0.right.equalToSuperview().offset(ScaleWidth(at: -15))
            $0.centerX.equalToSuperview()
        }
        
        exportButtonLabel.snp.makeConstraints {
            $0.top.equalTo(exportOTPButton.snp.top).offset( ScaleWidth(at: 15))
            $0.height.equalTo(ScaleWidth(at: 22.5))
            $0.leading.equalTo(exportOTPButton.snp.leading).offset(21.5)
        }
        
        exportButtonHint.snp.makeConstraints {
            $0.centerY.equalTo(exportButtonLabel.snp.bottom).offset( ScaleWidth(at: 11))
            $0.height.equalTo(ScaleWidth(at: 16.5))
            $0.width.equalTo(ScaleWidth(at: 216))
            $0.leading.equalTo(exportOTPButton.snp.leading).offset(21.5)
        }
        
        exportButtonImageView.snp.makeConstraints {
            $0.centerY.equalTo(exportOTPButton.snp.centerY)
            $0.height.equalTo(ScaleWidth(at: 11))
            $0.width.equalTo(ScaleWidth(at: 5.5))
            $0.trailing.equalTo(exportOTPButton.snp.trailing).offset(-16)
        }
        
        receiveButtonLabel.snp.makeConstraints {
            $0.top.equalTo(receiveOTPButton.snp.top).offset( ScaleWidth(at: 15))
            $0.height.equalTo(ScaleWidth(at: 22.5))
            $0.leading.equalTo(receiveOTPButton.snp.leading).offset(21.5)
        }
        
        receiveButtonHint.snp.makeConstraints {
            $0.centerY.equalTo(receiveButtonLabel.snp.bottom).offset( ScaleWidth(at: 11))
            $0.height.equalTo(ScaleWidth(at: 16.5))
            $0.width.equalTo(ScaleWidth(at: 216))
            $0.leading.equalTo(receiveOTPButton.snp.leading).offset(21.5)
        }
        
        receiveButtonImageView.snp.makeConstraints {
            $0.centerY.equalTo(receiveOTPButton.snp.centerY)
            $0.height.equalTo(ScaleWidth(at: 11))
            $0.width.equalTo(ScaleWidth(at: 5.5))
            $0.trailing.equalTo(receiveOTPButton.snp.trailing).offset(-16)
        }
        
        shareOTPRecordImageView.snp.makeConstraints {
            $0.top.equalTo(receiveOTPButton.snp.bottom).offset(27)
            $0.height.equalTo(ScaleWidth(at: 16))
            $0.width.equalTo(ScaleWidth(at: 19))
            $0.leading.equalTo(receiveOTPButton.snp.leading)
        }
        
        shareOTPRecordButton.snp.makeConstraints {
            $0.top.equalTo(receiveOTPButton.snp.bottom).offset(25)
            $0.height.equalTo(ScaleWidth(at: 21))
            $0.width.equalTo(ScaleWidth(at: 93.5))
            $0.left.equalTo(shareOTPRecordImageView.snp.right).offset(12)
        }
        
    }
    
    
    
}
