//
//  VersionUpdateViewController.swift
//  NoSMS
//
//  Created by azure on 2020/2/12.
//

import UIKit
import RxSwift
import RxCocoa

protocol VersionUpdateVCViewModelProtocol:BaseVCViewModelProtocol{
    
}
class VersionUpdateVCViewModel:BaseVCViewModel,VersionUpdateVCViewModelProtocol{
    
    
}
class VersionUpdateView: UIView {
    
    private let logoImageView: UIImageView = {
        
        let imageView = UIImageView(image: .noSmsLogo)
        
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    private let descriptionLabel: UILabel = {
        
        let label = UILabel()
        if let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
           label.setText("MustAuth V\(build)")
        }
        label.setTextAlignment(.center)
            .setFont(.pingFangMediumFont(size: 15))
            .setNumberOfLine(0)
            .setTextColor(.white)
        return label
    }()
    
    let button: UIButton = {
       
        let button = UIButton()
        
        button.setTitle("升级到 V1.2.1", for: .normal)
        button.addCornerAndBorder(backgroundColor: .clear, cornerRadius: ScaleWidth(at: 6), masksToBounds: false, borderColor: .homePageBorderColor, borderWidth: 1)
        button.titleLabel?.font = .pingFangMediumFont(size: 15)
        return button
    }()
    let latestDescLabel: UILabel = {
        
        let label = UILabel()
        
        label.setText("已是最新版本")
            .setTextAlignment(.center)
            .setFont(.pingFangMediumFont(size: 15))
            .setNumberOfLine(0)
            .setTextColor(.white)
        return label
    }()
    var tapButtonEvent: ControlEvent<Void> {
        
        return button.rx.tap
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .countColor
        addSubview(logoImageView)
        addSubview(descriptionLabel)
        addSubview(latestDescLabel)
        addSubview(button)
        
        logoImageView.snp.makeConstraints {
            
            $0.top.equalTo(ScaleWidth(at: 70))
            $0.left.equalTo(ScaleWidth(at: 137.5))
            $0.right.equalTo(ScaleWidth(at: -137.5))
            $0.height.equalTo(ScaleWidth(at: 100))
        }
        
        descriptionLabel.snp.makeConstraints {
            
            $0.centerX.equalTo(logoImageView)
            $0.top.equalTo(logoImageView.snp.bottom).offset(ScaleHeight(at: 20))
            $0.left.equalTo(ScaleWidth(at: 37.5))
            $0.right.equalTo(ScaleWidth(at: -37.5))
        }
        latestDescLabel.snp.makeConstraints{
            $0.centerX.equalTo(logoImageView)
        $0.top.equalTo(descriptionLabel.snp.bottom).offset(ScaleHeight(at: 10))
            $0.left.equalTo(ScaleWidth(at: 20))
            $0.right.equalTo(ScaleWidth(at: -20))
            $0.height.equalTo(ScaleWidth(at: 42))
        }
        button.snp.makeConstraints {
            
            $0.centerX.equalTo(logoImageView)
        $0.top.equalTo(descriptionLabel.snp.bottom).offset(ScaleHeight(at: 20))
            $0.left.equalTo(ScaleWidth(at: 20))
            $0.right.equalTo(ScaleWidth(at: -20))
            $0.height.equalTo(ScaleWidth(at: 42))
        }
        button.isHidden = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
class VersionUpdateViewControllerType<ViewModel: VersionUpdateVCViewModelProtocol>: BaseViewController<ViewModel> {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

class VersionUpdateViewController: VersionUpdateViewControllerType<VersionUpdateVCViewModel> {
    private let versionUpdateView: VersionUpdateView = .init(frame: .zero)
    convenience init() {
        let viewModel = VersionUpdateVCViewModel(navigationItem: BaseNavigaitonItem(title: .init(value: "关于")), backgroundColor: .clear)
        self.init(viewModel: viewModel)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.layer.shadowColor = UIColor.black.withAlphaComponent(0.12).cgColor
        navigationController?.navigationBar.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        navigationController?.navigationBar.layer.shadowRadius = 4.0
        navigationController?.navigationBar.layer.shadowOpacity = 1.0
        navigationController?.navigationBar.layer.masksToBounds = false
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .any, barMetrics: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        view.addSubview(versionUpdateView)
        versionUpdateView.snp.makeConstraints {
            $0.top.equalTo(view.snp.topMargin)
            $0.left.right.bottomMargin.equalToSuperview()
        }
        if let version = Repository.version {
            if version.code == 1 {
                versionUpdateView.button.isHidden = false
                versionUpdateView.latestDescLabel.isHidden = true
                if let strVersion = version.version_info?.version {
                        versionUpdateView.button.setTitle("升级到 V\(strVersion)", for: .normal)
                }
                
            }else {
                versionUpdateView.button.isHidden = true
                versionUpdateView.latestDescLabel.isHidden = false
            }
        }
        versionUpdateView.tapButtonEvent.subscribe(onNext: { [weak self] _ in
            guard let self = self else { return }
            
//            self.choseHowToAddTokenView.showView()
        }).disposed(by: disposedBag)
    }
}
