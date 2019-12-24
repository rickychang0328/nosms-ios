
import UIKit
import AVFoundation
import RxSwift
import RxCocoa

protocol QRCodeScannerProtocol {
    
    var qrCodeCaptureSession: AVCaptureSession { get }
    
    var eventResult: BehaviorSubject<QRCodeScanner.Event> { get }
    
}

class QRCodeScanner: NSObject, QRCodeScannerProtocol, AVCaptureMetadataOutputObjectsDelegate {
    
    let qrCodeCaptureSession: AVCaptureSession
    
    let eventResult: BehaviorSubject<Event>
    
    enum Event {
        
        case start
        case error(Error)
        case getQRCodeString(String)
    }
    
    override init() {
        
        self.eventResult = .init(value: .start)
        self.qrCodeCaptureSession = AVCaptureSession()
        super.init()
        
        do {
            let captureInput = try AVCaptureSessionFactory.creatAVCaptureInput(inputMediaType: .video)
            qrCodeCaptureSession.addInput(captureInput)
            
            AVCaptureSessionFactory.creatAVCaptureMetaDataOutput(session: qrCodeCaptureSession, delegate: self, types: [.qr], dispatchQueue: .main)
            
        } catch {
            
            eventResult.onNext(.error(error))
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                        didOutput metadataObjects: [AVMetadataObject],
                        from connection: AVCaptureConnection) {
        
        for metadata in metadataObjects {
            if let metadata = metadata as? AVMetadataMachineReadableCodeObject,
                metadata.type == .qr,
                let string = metadata.stringValue {
                    // Dispatch to the main queue because setMetadataObjectsDelegate doesn't
                qrCodeCaptureSession.stopRunning()
                eventResult.onNext(.getQRCodeString(string))
            }
        }
    }
}

struct AVCaptureSessionFactory {
    
    enum CaptureSessionError: Error {
        case noCaptureDevice
    }
    
    static func creatAVCaptureInput(inputMediaType: AVMediaType) throws -> AVCaptureInput {
        
        guard let captureDevice = AVCaptureDevice.default(for: inputMediaType) else {
            
            throw CaptureSessionError.noCaptureDevice
        }
        let captureInput = try AVCaptureDeviceInput(device: captureDevice)
        
        return captureInput
    }
    
    static func creatAVCaptureMetaDataOutput(session: AVCaptureSession,
                                             delegate: AVCaptureMetadataOutputObjectsDelegate,
                                             types: [AVMetadataObject.ObjectType],
                                             dispatchQueue: DispatchQueue) {
        
        let captureOutput = AVCaptureMetadataOutput()
        session.addOutput(captureOutput)
        captureOutput.setMetadataObjectsDelegate(delegate, queue: dispatchQueue)
        captureOutput.metadataObjectTypes = types
    }
}

enum TokenEvent {
    
    case start
    case error(Error)
    case endScanTask
    case alertAction(title: String, message: String, completion: () -> Void)
}

protocol TokenScannerVCViewModelProtocol: BaseVCViewModelProtocol {
    
    var captureSession: AVCaptureSession { get }
    var eventResult: BehaviorSubject<TokenEvent> { get }
    func startScan()
    func stopScan()
}

class TokenScannerViewModel: BaseVCViewModel, TokenScannerVCViewModelProtocol {
    
    
    let eventResult: BehaviorSubject<TokenEvent> = .init(value: .start)

    var captureSession: AVCaptureSession {
        
        return qrCodeScanner.qrCodeCaptureSession
    }
    
    private let qrCodeScanner: QRCodeScannerProtocol
    
    private let tokenStore: TokenStoreProtocol
    
    init(navigationItem: BaseNavigaitonItemProtocol = BaseNavigaitonItem(title: .init(value: "相机扫描二维码")),
        backgroundColor: UIColor = .clear,
        tokenStore: TokenStoreProtocol = KeychainTokenStore.shared,
        qrCodeScanner: QRCodeScannerProtocol = QRCodeScanner()) {
        
        self.tokenStore = tokenStore
        self.qrCodeScanner = qrCodeScanner
        super.init(navigationItem: navigationItem, backgroundColor: backgroundColor)
        
        qrCodeScanner.eventResult.subscribe(onNext: { [weak self] result in
            
            guard let self = self else { return }
            switch result {
                
            case .start:
                break
            case .error(let error):
                self.eventResult.onNext(.error(error))
            case .getQRCodeString(let string):
                
                self.tokenStore.addTokenWith(urlString: string, eventHandler: { [weak self] event in
                        
                    guard let self = self else { return }
                    
                    switch event {
                        
                    case .addSuccess:
                        
                        self.eventResult.onNext(.endScanTask)
                    case .haveTheSame(title: let title, message: let message, completion: let completion):
                        
                        self.eventResult.onNext(.alertAction(title: title, message: message, completion: completion))
                    case .addError(let error):
                        
                        self.eventResult.onNext(.error(error))
                    }
                })
            }
        }).disposed(by: disposedBag)
    }
    
    func startScan() {
        
        captureSession.startRunning()
    }
    
    func stopScan() {
        
        captureSession.stopRunning()
    }
}

class TokenScannerViewController<ViewModel: TokenScannerVCViewModelProtocol>: BaseViewController<ViewModel> {
    
    private let videoLayer = AVCaptureVideoPreviewLayer()
    
    private let maskLayer = CAShapeLayer()
    
    private let coverView: UIView = {
       
        let view = UIView()
        view.setBackgroundColor(.backCoverColor)
        return view
    }()
    
    private let screenImageView: UIImageView = {
        
        let imageView = UIImageView(image: .noSmsScreen)
        imageView.contentMode = .scaleToFill
        return imageView
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        videoLayer.videoGravity = .resizeAspectFill
        videoLayer.frame = view.layer.bounds
        view.layer.addSublayer(videoLayer)
        videoLayer.session = viewModel.captureSession
        
        let imageCGRect = CGRect(x: ScaleWidth(at: 35), y: ScaleHeight(at: 166), width: ScaleWidth(at: 305), height: ScaleWidth(at: 305))
        let maskLayerCGRect = CGRect(x: ScaleWidth(at: 41), y: ScaleHeight(at: 172), width: ScaleWidth(at: 293), height: ScaleWidth(at: 293))
        let path = UIBezierPath(rect: UIScreen.main.bounds)
        let tempPath = UIBezierPath(roundedRect: maskLayerCGRect, cornerRadius: ScaleWidth(at: 15))
        path.append(tempPath)
        path.usesEvenOddFillRule = true
        maskLayer.path = path.cgPath
        maskLayer.fillColor = UIColor.backCoverColor.cgColor
        maskLayer.fillRule = .evenOdd
        let view = UIView(frame: UIScreen.main.bounds)
        view.setBackgroundColor(.black)
            .alpha = 0.6
        view.layer.mask = maskLayer
        self.view.addSubview(view)
        
        screenImageView.frame = imageCGRect
        
        self.view.addSubview(screenImageView)
        
        viewModel.eventResult.subscribe(onNext: { [weak self] result in
            
            guard let self = self else { return }
            switch result {
                
            case .start:
                break
            case .error(let error):
                print(error)
                self.errorAlertHandler()
            case .endScanTask:
                
                NoSMSHUD.showToast(title: "识别成功！") { [weak self] in
                    
                    self?.navigationController?.popViewController(animated: true)
                }
            case .alertAction(title: let title, message: let message, completion: let completion):
                
                self.showAlert(title: title, message: message, confirmTitle: "确认", cancelTitle: "取消", confirmAction: completion) { [weak self] in
                    self?.viewModel.startScan()
                }
                
            }
        }).disposed(by: disposedBag)
        
    }
    
    private func errorAlertHandler() {
        
        NoSMSHUD.showToast(title: "未识别出有效二维码") { [weak self] in
            
            self?.viewModel.startScan()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.startScan()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.stopScan()
    }
}
