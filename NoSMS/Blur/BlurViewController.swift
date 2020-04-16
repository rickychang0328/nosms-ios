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

class BlurViewController: UIViewController {
    
    static let shared: BlurViewController = .init()
    
    let blurView = DynamicBlurView(frame: .zero)

    private var lifeCycleDisposeBag: DisposeBag = .init()
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        reset()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        modalPresentationStyle = .overFullScreen
        view.backgroundColor = .clear
        view.addSubview(blurView)
        blurView.snp.makeConstraints {
            $0.top.left.right.bottom.equalToSuperview()
        }
        blurView.blurRadius = 15
        blurView.isDeepRendering = true
        blurView.iterations = 10
        blurView.blurRatio = 0.6
    }
    
    func reset() {
        
        blurView.refresh()
        blurView.animate()
    }
}
