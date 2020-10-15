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
        button.backgroundColor = .otpShareReceiveButtonColor
        button.frame = CGRect(x: 0, y: 0, width: 345, height: 42)
        button.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            let newViewController = ShareOTPViewController(viewModel: TokenListVCViewModel())
            self.navigationController?.pushViewController(newViewController, animated: true)
            
        }).disposed(by: disposedBag)
        return button
    }()
    
    private lazy var receiveOTPButton: UIButton = {
        
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.backgroundColor = .otpShareReceiveButtonColor
        button.frame = CGRect(x: 0, y: 0, width: 345, height: 42)
        button.addCornerRadius(at: 10)
        button.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            
            let nextVC = TokenScannerViewController(viewModel: TokenScannerViewModel())
            self.navigationController?.pushViewController(nextVC, animated: true)
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
        button.addCornerRadius(at: 10)
        button.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            let newViewController = OTPShareRecordViewController()
            newViewController.view.backgroundColor = .optShareRecordBackgroundColor
            self.navigationController?.pushViewController(newViewController, animated: true)
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
        label.textColor = .otpShareReceiveButtonTextColor
        label.frame = CGRect(x: 0, y: 0, width: 345, height: 42)
        return label
    }()
    
    private lazy var receiveButtonLabel: UILabel = {
        let label = UILabel()
        label.text = "导入验证码"
        label.font = UIFont(name: TFontName.PingFangFontMedium.rawValue , size: 16)
        label.textAlignment = .left
        label.textColor = .otpShareReceiveButtonTextColor
        label.frame = CGRect(x: 0, y: 0, width: 345, height: 42)
        return label
    }()
    
    private lazy var exportButtonHint: UILabel = {
        let label = UILabel()
        label.text = "选择欲导出的验证码，并创建您的二维码。"
        label.font = UIFont(name: TFontName.PingFangFontMedium.rawValue , size: 12)
        label.textAlignment = .left
        label.textColor = UIColor.getColor(red: 136, green: 136, blue: 138, alpha: 1)
        label.frame = CGRect(x: 0, y: 0, width: 345, height: 42)
        return label
    }()
    
    private lazy var receiveButtonHint: UILabel = {
        let label = UILabel()
        label.text = "扫描设备的二维码即可导入验证码。"
        label.font = UIFont(name: TFontName.PingFangFontMedium.rawValue , size: 12)
        label.textAlignment = .left
        label.textColor = UIColor.getColor(red: 136, green: 136, blue: 138, alpha: 1)
        label.frame = CGRect(x: 0, y: 0, width: 345, height: 42)
        return label
    }()
    
    private lazy var shareOTPImageView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(named: "NOSMS_sharecodeLightIcon")
        view.backgroundColor = .clear
        return view
    }()
    
    private lazy var shareOTPRecordImageView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(named: "NoSMS_historyIcon")
        view.backgroundColor = UIColor.clear
        return view
    }()
    
    private lazy var exportButtonImageView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(named: "NoSMS_narrow")
        return view
    }()
    
    private lazy var receiveButtonImageView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(named: "NoSMS_narrow")
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.view.backgroundColor = .tokenListBackgroundColor
        setLayOut()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        self.navigationItem.title = "验证码分享"
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        navigationController?.navigationBar.barTintColor = .navigationColor
        self.navigationItem.title = ""
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setNavigate()
    }
    
    func setNavigate() {
        var color: UIColor
        if #available(iOS 13.0, *) {
            
            if UITraitCollection.current.userInterfaceStyle == .some(.dark) {
                
                color = .getColor(red: 33, green: 33, blue: 33, alpha: 0.56)
            } else {
                
                color = .navColorLight
            }
        } else {
            color = .navColorLight
            // Fallback on earlier versions
        }
        navigationController?.navigationBar.barTintColor = color
    }
    
    private func setLayOut() {
        self.navigationItem.title = "验证码分享"
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: self, action: nil)
        setNavigate()
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
            $0.top.equalTo(shareOTPImageView.snp.bottom).offset(ScaleWidth(at: 20))
            $0.left.equalToSuperview().offset(ScaleWidth(at: 18))
            $0.right.equalToSuperview().offset(ScaleWidth(at: -18))
            $0.height.equalTo(ScaleWidth(at: 80))
            $0.centerX.equalToSuperview()
        }
        
        exportOTPButton.snp.makeConstraints {
            $0.top.equalTo(topHint.snp.bottom).offset(ScaleWidth(at: 0))
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
            $0.top.equalTo(exportButtonLabel.snp.bottom).offset(ScaleWidth(at: 11))
            $0.height.equalTo(ScaleWidth(at: 16.5))
            $0.width.equalTo(ScaleWidth(at: 216))
            $0.leading.equalTo(exportOTPButton.snp.leading).offset(21.5)
        }
        
        exportButtonImageView.snp.makeConstraints {
            $0.centerY.equalTo(exportOTPButton.snp.centerY)
            $0.height.equalTo(ScaleWidth(at: 35))
            $0.width.equalTo(ScaleWidth(at: 35))
            $0.trailing.equalTo(exportOTPButton.snp.trailing).offset(-10)
        }
        
        receiveButtonLabel.snp.makeConstraints {
            $0.top.equalTo(receiveOTPButton.snp.top).offset( ScaleWidth(at: 15))
            $0.height.equalTo(ScaleWidth(at: 22.5))
            $0.leading.equalTo(receiveOTPButton.snp.leading).offset(21.5)
        }
        
        receiveButtonHint.snp.makeConstraints {
            $0.top.equalTo(receiveButtonLabel.snp.bottom).offset( ScaleWidth(at: 11))
            $0.height.equalTo(ScaleWidth(at: 16.5))
            $0.width.equalTo(ScaleWidth(at: 216))
            $0.leading.equalTo(receiveOTPButton.snp.leading).offset(21.5)
        }
        
        receiveButtonImageView.snp.makeConstraints {
            $0.centerY.equalTo(receiveOTPButton.snp.centerY)
            $0.height.equalTo(ScaleWidth(at: 35))
            $0.width.equalTo(ScaleWidth(at: 35))
            $0.trailing.equalTo(receiveOTPButton.snp.trailing).offset(-10)
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
