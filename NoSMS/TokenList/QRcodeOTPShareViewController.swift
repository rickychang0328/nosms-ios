//
//  QRcodeOTPShareViewController.swift
//  NoSMS
//
//  Created by Andy LI on 2020/10/7.
//

import UIKit
import RxSwift
import RxCocoa
import RealmSwift

class QRcodeOTPShareViewController: UIViewController {
    
    var disposedBag: DisposeBag = .init()
    private let startTime = Date().timeIntervalSince1970
    private let timeCounter: TimeInterval = 61
    var pageInex = 1
    var page = 1
    var currentDate: Date?
    var otpShareSelectedAccountDatatoken = [Data]()
    var otpShareSelectedAccount = [String]()
    var otpShareSelectedAccountToken = [String]()
    var timer : Timer?
    var showOTPAmount = 8
    let alertVc = NoSMSAlertOneButtonViewController()
    
    lazy var alertView: NoSMSAlertScanOneButtonView = {
        
        let view = NoSMSAlertScanOneButtonView(frame: .zero)
            .addCornerRadius(at: ScaleWidth(at: 20))
        view.oneButtonAlertCase = .screenShot
        view.isHidden = true
        view.confirmButton.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        
        return view
    }()
    
    @objc func buttonAction(sender: UIButton!) {
        alertView.isHidden = true
    }
    
    private lazy var exportOTPButton: UIButton = {
        
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.setTitle("完成", for: .normal)
        button.titleLabel?.textColor = .white
        button.backgroundColor = UIColor.getColor(red: 98, green: 112, blue: 255, alpha: 1)
        button.frame = CGRect(x: 0, y: 0, width: 345, height: 42)
        button.addCornerRadius(at: 6)
        if self.page > 1 {
            button.isHidden = true
        }
        button.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.popViewControllerss(popViews: 2)
        }).disposed(by: disposedBag)
        return button
    }()
    
    private lazy var nextButton: UIButton = {
        
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.setTitle("下一页", for: .normal)
        button.titleLabel?.textColor = .white
        button.backgroundColor = UIColor.getColor(red: 98, green: 112, blue: 255, alpha: 1)
        button.frame = CGRect(x: 0, y: 0, width: 345, height: 42)
        button.addCornerRadius(at: 6)
        if page == 1 {
            button.isHidden = true
            exportOTPButton.isHidden = false
        }
        button.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.pageInex += 1
            self.setQRcodeImageView(pageindex: self.pageInex)
            self.previousButton.isHidden = false
            if self.page == self.pageInex {
                button.isHidden = true
                self.exportOTPButton.isHidden = false
            }
            self.qrCodeIndex.text = "扫描第 \(self.pageInex)/\(self.page) 个二维码"
        }).disposed(by: disposedBag)
        return button
    }()
    
    private lazy var previousButton: UIButton = {
        let button = UIButton(type: UIButton.ButtonType.custom)
        button.setTitle("上一页", for: .normal)
        button.setTitleColor(UIColor.getColor(red: 98, green: 112, blue: 255, alpha: 1), for: .normal)
        button.backgroundColor = .tokenListBackgroundColor
        button.frame = CGRect(x: 0, y: 0, width: 345, height: 42)
        button.addCornerRadius(at: 6)
        button.isHidden = true
        button.layer.borderWidth = 0.8
        button.layer.borderColor = UIColor.getColor(red: 98, green: 112, blue: 255, alpha: 1).cgColor
        button.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            self.pageInex -= 1
            self.setQRcodeImageView(pageindex: self.pageInex)
            self.nextButton.isHidden = false
            if self.self.pageInex == 1 {
                button.isHidden = true
            }
            self.qrCodeIndex.text = "扫描第 \(self.pageInex)/\(self.page) 个二维码"
        }).disposed(by: disposedBag)
        return button
    }()
    
    private lazy var topHint: UILabel = {
        
        let label = UILabel()
        label.text = "在您的新设备上，开启 MustAuth 扫描二维码"
        label.adjustsFontSizeToFitWidth = true
        label.sizeToFit()
        label.textAlignment = .center
        label.textColor = UIColor.getColor(red: 102, green: 102, blue: 102, alpha: 1)
        label.frame = CGRect(x: 0, y: 0, width: 345, height: 42)
        return label
    }()
    
    private lazy var qrCodeIndex: UILabel = {
        let label = UILabel()
        label.text = "扫描第 \(self.pageInex)/\(page) 个二维码"
        label.font = .pingFangSemiBoldFont(size: 16)
        label.textAlignment = .center
        label.textColor = UIColor.getColor(red: 102, green: 102, blue: 102, alpha: 1)
        label.frame = CGRect(x: 0, y: 0, width: 345, height: 42)
        if page == 1 {
            label.isHidden = true
        }
        return label
    }()
    
    private lazy var timeCount: UILabel = {
        let label = UILabel()
        label.text = "00:60 请在倒数计时结束前完成扫码"
        label.textAlignment = .center
        label.textColor = UIColor.getColor(red: 102, green: 102, blue: 102, alpha: 1)
        label.frame = CGRect(x: 0, y: 0, width: 345, height: 42)
        return label
    }()
    
    private lazy var checkOTPButton: UIButton = {
        let button = UIButton()
        button.setTitle("查看此二维码包含的验证码", for: .normal)
        button.setTitleColor(UIColor.getColor(red: 98, green: 112, blue: 255, alpha: 1), for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 345, height: 42)
        button.rx.tap.subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            let view = ShareSelectedOTPViewController()
            var startIndex = self.showOTPAmount * (self.pageInex-1)
            var endIndex = startIndex + 7
            if self.otpShareSelectedAccount.count - 1 < endIndex {
                endIndex = self.otpShareSelectedAccount.count - 1
            }
            var thisPageQRCodeAccount = [String]()
            for index in startIndex...endIndex {
                thisPageQRCodeAccount.append(self.otpShareSelectedAccount[index])
            }
            view.otpValueArray = thisPageQRCodeAccount
            view.confirmButton.rx.tap.subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                view.view.removeFromSuperview()
            }).disposed(by: self.disposedBag)
            self.view.addSubview(view.view)
        }).disposed(by: disposedBag)
        return button
    }()
    
    private lazy var qrCodeView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white
        view.addCornerRadius(at: 25)
        return view
    }()
    
    private lazy var qrCodeImageView: UIImageView = {
        let view = UIImageView()
        view.backgroundColor = UIColor.white
        return view
    }()
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        timer?.invalidate()
        alertVc.dismiss(animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setNavigate()
        self.navigationItem.title = "扫描二维码"
        page = self.otpShareSelectedAccountDatatoken.count / showOTPAmount
        if page == 0 {
            page = 1
        } else if self.otpShareSelectedAccountDatatoken.count % showOTPAmount > 0 {
            page += 1
        }
        setLayOut()
        addNotification()
        initTokenArray()
        setQRcodeImageView(pageindex: 1)
        addTimer()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setNavigate()
    }
    
    func setNavigate() {
        let leftbarItem = UIBarButtonItem(image: .noSmsBack, style: .plain, target: nil, action: nil)
        
        leftbarItem.rx.tap.subscribe(onNext: {[weak self] in
            
            self?.navigationController?.popViewController(animated: true)
        }).disposed(by: disposedBag)
        navigationItem.leftBarButtonItem = leftbarItem
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
    private func initTokenArray() {
        let tokenStore: TokenStoreProtocol = KeychainTokenStore.shared
        for tokenID in otpShareSelectedAccountDatatoken {
            for token in tokenStore.tokenList {
                if tokenID == token.uuid {
                    RealmDataManager.addOTPShareAccount(token, time: currentDate ?? Date())
                    otpShareSelectedAccount.append("[\(token.token.issuer)] \(token.token.name)" )
                    var adapterToken:URL
                    do {
                        adapterToken = try token.getMustAuthTokenURL()
                        otpShareSelectedAccountToken.append(adapterToken.debugDescription)
                    } catch {
                        print("User creation failed with error: \(error)")
                    }
                }
            }
        }
    }
    
    private func setQRcodeImageView(pageindex: Int) {
        let startIndex = (pageindex - 1) * showOTPAmount
        var endIndex = startIndex + 7
        if endIndex >= otpShareSelectedAccount.count {
            endIndex = otpShareSelectedAccount.count - 1
        }
        
        var urlcom = URLComponents()
        urlcom.scheme = MustAuth.kMustAuthScheme
        urlcom.host = MustAuth.kQueryActionMulitpleshare
        urlcom.path = "/\(MustAuth.kQueryActionMulitpleshare)"
        
        let action = URLQueryItem(name: MustAuth.kQueryActionKey, value: MustAuth.kQueryActionMulitpleshare)
        var mulitpleURLArray = [URLQueryItem]()
        
        for index in startIndex...endIndex {
            let token = otpShareSelectedAccountToken[index]
            let mulitpleURL = URLQueryItem(name: MustAuth.kQueryMulitpleURLKey, value: token)
            mulitpleURLArray.append(mulitpleURL)
            //url += "&\(token)"
        }
        urlcom.queryItems = [action] + mulitpleURLArray
        qrCodeImageView.image =  urlcom.url?.debugDescription.generateQRCode()
    }
    
    private func addTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { (Timer) in
            
            let lastTime = Date().timeIntervalSince1970 - self.startTime
            
            if lastTime > self.timeCounter {
                
                self.timer?.invalidate()
                self.popViewControllerss(popViews: 2)
            } else {
                
                let displayTime = self.timeCounter - lastTime
                
                let firstTime: String
                
                if displayTime >= 10 {
                    
                    firstTime = "00:"
                } else {
                    
                    firstTime = "00:0"
                }
                
                self.timeCount.text =  firstTime + "\(Int(displayTime))" + " 请在倒数计时结束前完成扫码"
            }
        }
    }
    
    private func addNotification() {
        NotificationCenter.default.addObserver(forName: UIApplication.userDidTakeScreenshotNotification, object: nil, queue: OperationQueue.main) { notification in
            self.alertView.isHidden = false
        }
    }
    
    private func setLayOut() {
        self.view.addSubview(exportOTPButton)
        self.view.addSubview(topHint)
        self.view.addSubview(qrCodeView)
        self.view.addSubview(qrCodeImageView)
        self.view.addSubview(alertView)
        self.view.addSubview(timeCount)
        self.view.addSubview(checkOTPButton)
        self.view.addSubview(nextButton)
        self.view.addSubview(previousButton)
        self.view.addSubview(qrCodeIndex)
        
        alertView.snp.makeConstraints {
            
            $0.edges.equalTo(qrCodeView)
        }
        
        if page == 1 {
            exportOTPButton.snp.makeConstraints {
                $0.bottom.equalTo(view.snp.bottomMargin).offset(ScaleHeight(at: -14))
                $0.left.equalToSuperview().offset(ScaleWidth(at: 15))
                $0.right.equalToSuperview().offset(ScaleWidth(at: -15))
                $0.height.equalTo(ScaleWidth(at: 42))
                $0.centerX.equalToSuperview()
            }
        } else {
            exportOTPButton.snp.makeConstraints {
                $0.bottom.equalTo(view.snp.bottomMargin).offset(ScaleHeight(at: -14))
                $0.right.equalToSuperview().offset(ScaleWidth(at: -15))
                $0.height.equalTo(ScaleWidth(at: 42))
                $0.width.equalTo(ScaleWidth(at: 130))
            }
        }
        
        nextButton.snp.makeConstraints {
            $0.bottom.equalTo(view.snp.bottomMargin).offset(ScaleHeight(at: -14))
            $0.right.equalToSuperview().offset(ScaleWidth(at: -15))
            $0.height.equalTo(ScaleWidth(at: 42))
            $0.width.equalTo(ScaleWidth(at: 130))
        }
        
        previousButton.snp.makeConstraints {
            $0.bottom.equalTo(view.snp.bottomMargin).offset(ScaleHeight(at: -14))
            $0.left.equalToSuperview().offset(ScaleWidth(at: 15))
            $0.height.equalTo(ScaleWidth(at: 42))
            $0.width.equalTo(ScaleWidth(at: 130))
        }
        
        topHint.snp.makeConstraints {
            $0.top.equalTo(ScaleHeight(at: 124.5))
            $0.width.equalTo(ScaleWidth(at: 305))
            $0.height.equalTo(ScaleWidth(at: 21))
            $0.centerX.equalToSuperview()
        }
        
        qrCodeIndex.snp.makeConstraints {
            
            $0.top.equalTo(ScaleHeight(at: 72))
            $0.left.equalToSuperview().offset(ScaleWidth(at: 17))
            $0.right.equalToSuperview().offset(ScaleWidth(at: -17))
            $0.height.equalTo(ScaleWidth(at: 21))
            $0.centerX.equalToSuperview()
        }
        
        qrCodeView.snp.makeConstraints {
            $0.top.equalTo(topHint.snp.bottom).offset(ScaleHeight(at: 53))
            $0.height.equalTo(topHint.snp.width)
            $0.width.equalTo(topHint.snp.width)
            $0.centerX.equalToSuperview()
        }
        
        qrCodeImageView.snp.makeConstraints {
            $0.height.equalTo(ScaleWidth(at: 225))
            $0.width.equalTo(ScaleWidth(at: 225))
            $0.centerX.equalTo(qrCodeView.snp.centerX)
            $0.centerY.equalTo(qrCodeView.snp.centerY)
        }
        if UIDevice.isIPhoneXUp {
            timeCount.snp.makeConstraints {
                $0.top.equalTo(qrCodeView.snp.bottom).offset(ScaleWidth(at: 35))
                $0.left.equalTo(ScaleWidth(at: 17))
                $0.right.equalTo(ScaleWidth(at: -17))
                $0.height.equalTo(ScaleWidth(at: 21))
            }
        } else if UIScreen.main.nativeBounds.height <= 1334 {
            timeCount.snp.makeConstraints {
                $0.top.equalTo(qrCodeView.snp.bottom).offset( ScaleWidth(at: 5))
                $0.left.equalTo(ScaleWidth(at: 17))
                $0.right.equalTo(ScaleWidth(at: -17))
                $0.height.equalTo(ScaleWidth(at: 21))
            }
            
        } else {
            timeCount.snp.makeConstraints {
                $0.top.equalTo(qrCodeView.snp.bottom).offset( ScaleWidth(at: 18))
                $0.left.equalTo(ScaleWidth(at: 17))
                $0.right.equalTo(ScaleWidth(at: -17))
                $0.height.equalTo(ScaleWidth(at: 21))
            }
        }
        
        checkOTPButton.snp.makeConstraints {
            $0.top.equalTo(timeCount.snp.bottom).offset( ScaleWidth(at: 7.5))
            $0.left.equalTo(ScaleWidth(at: 17))
            $0.right.equalTo(ScaleWidth(at: -17))
            $0.height.equalTo(ScaleWidth(at: 21))
        }
    }
    
    
}

extension String {
    
    func generateQRCode() -> UIImage? {
        let data = self.data(using: String.Encoding.ascii)
        
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 3, y: 3)
            
            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }
        
        return nil
    }
    
}

extension UIViewController {
    func popViewControllerss(popViews: Int, animated: Bool = true) {
        if self.navigationController!.viewControllers.count > popViews
        {
            let vc = self.navigationController!.viewControllers[self.navigationController!.viewControllers.count - popViews - 1]
            self.navigationController?.popToViewController(vc, animated: animated)
        }
    }
}

class ShareSelectedOTPViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let disposeBag: DisposeBag = .init()
    var tableView = UITableView()
    
    var otpValueArray = [""]
    
    let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .getColor(red: 41, green: 44, blue: 68, alpha: 1)
        view.addCornerRadius(at: 10)
        return view
    }()
    
    
    let confirmButton: UIButton = {
        let button = UIButton()
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .pingFangMediumFont(size: 15)
        button.titleLabel?.setTextAlignment(.center)
        button.addCornerRadius(at: ScaleWidth(at: 4))
        button.backgroundColor = .getColor(red: 98, green: 112, blue: 255, alpha: 1)
        button.setTitle("确认", for: .normal)
        button.addTarget(self, action: #selector(confirm), for: .touchUpInside)
        return button
    }()
    
    let titleLabel: UILabel = {
        
        let label = UILabel()
        label.text = "包含验证码"
        label.setFont(.pingFangMediumFont(size: 15))
            .setTextColor(.white)
            .setNumberOfLine(0)
            .setTextAlignment(.center)
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .getColor(red: 0, green: 0, blue: 0, alpha: 0.4)
        tableView.register(ShareOTPTableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.allowsSelection = false
        containerView.addSubview(tableView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(confirmButton)
        view.addSubview(containerView)
        titleLabel.preferredMaxLayoutWidth = ScaleWidth(at: 235)
        titleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(ScaleWidth(at: 25))
            $0.left.equalToSuperview().offset(20)
            $0.right.equalToSuperview().offset(-20)
            $0.height.equalTo(21)
        }
        containerView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(ScaleWidth(at: 151.5))
            $0.left.equalToSuperview().offset(49.5)
            $0.right.equalToSuperview().offset(-49.5)
            $0.height.equalTo(337 - 20 * (8 - otpValueArray.count) - 20)
        }
        
        confirmButton.snp.makeConstraints {
            
            $0.height.equalTo(ScaleWidth(at: 37))
            $0.bottom.equalToSuperview().offset(ScaleWidth(at: -10.5))
            $0.left.equalToSuperview().offset(10.5)
            $0.right.equalToSuperview().offset(-10.5)
        }
        
        tableView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(ScaleWidth(at: 61))
            $0.left.equalToSuperview().offset(10.5)
            $0.right.equalToSuperview().offset(-10.5)
            $0.bottom.equalTo(confirmButton.snp.top).offset(ScaleWidth(at: 25))
        }
        
    }
    
    @objc func confirm(sender:UIButton!) {
        self.view.removeFromSuperview()
    }
    
    // return the number of cells each section.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return otpValueArray.count
    }
    
    // return cells
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ShareOTPTableViewCell
        cell.otpValue.text = otpValueArray[indexPath.row]
        cell.backgroundColor = .clear
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 20
    }
    
    
}

class ShareOTPTableViewCell: UITableViewCell {
    
    var otpValue: UILabel = {
        let label = UILabel()
        label.text = ""
        label.backgroundColor = .clear
        label.setFont(.pingFangMediumFont(size: 13))
            .setTextColor(.getColor(red: 216, green: 216, blue: 216, alpha: 1))
            .setNumberOfLine(0)
            .setTextAlignment(.left)
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = .clear
        contentView.addSubview(otpValue)
        otpValue.snp.makeConstraints {
            $0.height.equalToSuperview()
            $0.left.equalToSuperview().offset(10.5)
            $0.right.equalToSuperview().offset(-10.5)
            $0.centerX.equalToSuperview()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class NoSMSAlertScanOneButtonView: UIView {
    
    var oneButtonAlertCase: OneButtonAlertCase = .normal
    var disposedBag: DisposeBag = .init()
    
    lazy var confirmButton: UIButton = {
        
        let button = UIButton()
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .pingFangMediumFont(size: 15)
        button.titleLabel?.setTextAlignment(.center)
        button.addCornerRadius(at: ScaleWidth(at: 10))
        button.setTitle("知道了", for: .normal)
        button.backgroundColor = .getColor(red: 98, green: 112, blue: 255, alpha: 1)
        return button
    }()
    
    let titleLabel: UILabel = {
        
        let label = UILabel()
        label.setFont(.pingFangSemiBoldFont(size: 15))
            .setTextColor(.alertScanTextColor)
            .setNumberOfLine(0)
            .setTextAlignment(.center)
        label.text = "此功能用于验证码分享，"
        return label
    }()
    
    let titleSecondLabel: UILabel = {
        
        let label = UILabel()
        label.setFont(.pingFangSemiBoldFont(size: 15))
            .setTextColor(.alertScanTextColor)
            .setNumberOfLine(0)
            .setTextAlignment(.center)
        label.text = "请不要将二维码发送给他人。"
        return label
    }()
    
    func setAlertCase(alertCase: OneButtonAlertCase) {
        oneButtonAlertCase = alertCase
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .alertScanViewColor
        alpha = 0.95
        addSubview(titleLabel)
        addSubview(titleSecondLabel)
        addSubview(confirmButton)
        
        titleLabel.preferredMaxLayoutWidth = ScaleWidth(at: 235)
        titleLabel.snp.makeConstraints {
            $0.top.equalTo(ScaleWidth(at: 110))
            $0.centerX.equalToSuperview()
            $0.left.equalToSuperview().offset(20)
            $0.right.equalToSuperview().offset(-20)
        }
        
        titleSecondLabel.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(5)
            $0.centerX.equalToSuperview()
            $0.left.equalToSuperview().offset(20)
            $0.right.equalToSuperview().offset(-20)
        }
        
        
        confirmButton.snp.makeConstraints {
            
            $0.height.equalTo(ScaleWidth(at: 42))
            $0.top.equalTo(titleSecondLabel.snp.bottom).offset(20)
            $0.width.equalTo(ScaleWidth(at: 214))
            $0.centerX.equalToSuperview()
            
        }
        
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

