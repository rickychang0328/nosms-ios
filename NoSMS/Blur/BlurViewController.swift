//
//  BlurViewController.swift
//  NoSMS
//
//  Created by azure on 2020/4/14.
//

import UIKit
import SnapKit
import RxSwift
import BiometricAuthentication
import DynamicBlurView
import Foundation


//MARK: 用 ViewController 有些地方有點坑, 會帶到之前 VC 的 view
class CustomBlurView: UIView {
    
    let blurView = DynamicBlurView(frame: .zero)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(blurView)
        
        blurView.snp.makeConstraints {
            
            $0.edges.equalToSuperview()
        }
        
        blurView.blurRadius = 15
        blurView.isDeepRendering = true
        blurView.iterations = 10
        blurView.blurRatio = 0.6
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class BlurViewController: UIViewController {
    
    static let shared: BlurViewController = .init()
    
    let blurView = DynamicBlurView(frame: .zero)
    private var isFirstOpen:Bool = true
    private var lifeCycleDisposeBag: DisposeBag = .init()
    override func viewDidLoad() {
        super.viewDidLoad()
        modalPresentationStyle = .overFullScreen
        view.backgroundColor = .clear
        view.addSubview(blurView)
        blurView.snp.makeConstraints {
            $0.top.left.right.bottom.equalToSuperview()
        }
//        blurView.trackingMode = .tracking
//        blurView.blendMode = .hardLight
        blurView.blurRadius = 15
        blurView.isDeepRendering = true
        blurView.iterations = 10
        blurView.blurRatio = 0.6
//        blurView.isHidden = true
        //        blurView.blendMode = .difference
        //        blurView.alpha = 0.8
        //        blurView.backgroundColor = .white

        // Do any additional setup after loading the view.
        showBiomatricAuthenticaion()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    func showBiomatricAuthenticaion(){
//        NotificationCenter.default.rx.notification(UIApplication.didBecomeActiveNotification).subscribe({[weak self] _ in
//                        guard let self = self else { return }
////                    if self.isFirstOpen {
////                        self.isFirstOpen = false
////                        return
////                    }
//            if let backgroundDate = UserDefaults.standard.object(forKey: UserDefaults.Key.enterBackgroundTime.string) as? Date{
//                let nowDate = Date()
//                let userCalendar = Calendar.current
//                let timeDiff = userCalendar.dateComponents([.hour,.minute,.second], from: backgroundDate, to: nowDate)
//                let isTerminateApp = UserDefaults.standard.bool(forKey: UserDefaults.Key.isAppTerminate.string)
//                print("minute:\(timeDiff.minute),second:\(timeDiff.second)")
//                let isShowAuthentication = (timeDiff.minute ?? 0) >= 5 || isTerminateApp
//                if isShowAuthentication {
//                    BioMetricAuthenticator.authenticateWithBioMetrics(reason: "") { (result) in
//
//                        switch result {
//                            case .success( _):
//                                if !UserDefaults.standard.bool(forKey: UserDefaults.Key.faceIDString.string) {
//                                    UserDefaults.standard.set(true, forKey: UserDefaults.Key.faceIDString.string)
//                                }
//                                self.removeVC()
//                                // authentication successful
//    //                                self?.showLoginSucessAlert()
//    //                                       self.blurView.isHidden = true
//                                break
//                            case .failure(let error):
//
//                                switch error {
//
//                                // device does not support biometric (face id or touch id) authentication
//                                case .biometryNotAvailable:
//                                    self.showErrorAlert(message: error.message())
//                                    break
//                                // No biometry enrolled in this device, ask user to register fingerprint or face
//                                case .biometryNotEnrolled:
//    //                                    self?.showGotoSettingsAlert(message: error.message())
//                                    self.removeVC()
//                                // show alternatives on fallback button clicked
//                                case .fallback:
//    //                                    self?.txtUsername.becomeFirstResponder() // enter username password manually
//                                    self.removeVC()
//                                    // Biometry is locked out now, because there were too many failed attempts.
//                                // Need to enter device passcode to unlock.
//                                case .biometryLockedout:
//                                    self.showPasscodeAuthentication(message: error.message())
//
//                                // do nothing on canceled by system or user
//                                case .canceledBySystem, .canceledByUser:
//    //                                            self.view.removeFromSuperview()
//                                    self.removeVC()
//                                // show error for any other reason
//                                default:
//                                    self.showErrorAlert(message: error.message())
//                                    self.removeVC()
//    //                                            self.view.removeFromSuperview()
//                                }
//                            }
//                        }
//                }else{
//                    self.removeVC()
//                }
//
//
//            }
//
//
//
//            }).disposed(by: lifeCycleDisposeBag)
    }
    func removeVC(){
        self.view.removeFromSuperview()
        self.removeFromParent()
    }
    func showPasscodeAuthentication(message: String) {
            
            BioMetricAuthenticator.authenticateWithPasscode(reason: message) { [weak self] (result) in
                guard let self = self else { return }
                switch result {
                case .success( _):
    //                self?.showLoginSucessAlert() // passcode authentication success
                    self.view.removeFromSuperview()
                    break
                case .failure(let error):
                    print(error.message())
                }
            }
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
