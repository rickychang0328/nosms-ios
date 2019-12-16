
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
    
    init(navigationItem: BaseNavigaitonItemProtocol = BaseNavigaitonItem(title: .init(value: "扫描二微码")),
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
                
                do {
                    
                    try self.tokenStore.addTokenWith(urlString: string)
                    self.eventResult.onNext(.endScanTask)
                } catch {
                    
                    self.eventResult.onNext(.error(error))
                }
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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        videoLayer.videoGravity = .resizeAspectFill
        videoLayer.frame = view.layer.bounds
        view.layer.addSublayer(videoLayer)
        videoLayer.session = viewModel.captureSession
        
        viewModel.eventResult.subscribe(onNext: { [weak self] result in
            
            switch result {
                
            case .start:
                break
            case .error(let error):
                print(error)
                self?.errorAlertHandler()
            case .endScanTask:
                self?.navigationController?.popViewController(animated: true)
            }
        }).disposed(by: disposedBag)
        
    }
    
    private func errorAlertHandler() {
        
        showErrorAlert(title: "错误的QR码", message: nil) {
            
            self.viewModel.startScan()
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
