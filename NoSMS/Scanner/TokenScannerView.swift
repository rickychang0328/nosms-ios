import SwiftUI
import AVFoundation
import OneTimePassword
import Base32

class ScannerViewModel: NSObject, ObservableObject, AVCaptureMetadataOutputObjectsDelegate {
    @Published var scannerEvent: ScannerEvent? = nil
    
    enum ScannerEvent: Identifiable {
        case success(String)
        case error(String)
        case duplicate(message: String, primaryAction: () -> Void)
        case replaceOrNew(message: String, replaceAction: () -> Void, newAddAction: () -> Void)
        
        var id: UUID { UUID() }
    }
    
    let captureSession = AVCaptureSession()
    private let tokenService = TokenService.shared
    private var isConfigured = false
    
    override init() {
        super.init()
        setupSession()
    }
    
    private func setupSession() {
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
            isConfigured = true
        }
    }
    
    func startScanning() {
        guard isConfigured else { return }
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
            }
        }
    }
    
    func stopScanning() {
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            stopScanning()
            processScannedCode(stringValue)
        }
    }
    
    private func processScannedCode(_ code: String) {
        if let mulitpleURL = try? code.mustAuth.parsingMulitple() {
            processMultipleURLs(mulitpleURL.urlStrings)
        } else {
            processSingleURL(code)
        }
    }
    
    private func processSingleURL(_ urlString: String) {
        let urlConfirm: URL
        if let url = URL(string: urlString) {
            urlConfirm = url
        } else if let decodeURL = urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                  let url = URL(string: decodeURL) {
            urlConfirm = url
        } else {
            self.scannerEvent = .error("無法識別無效的網址")
            return
        }
        
        guard let token = Token(customURL: urlConfirm) else {
            self.scannerEvent = .error("無法識別無效的金鑰網址")
            return
        }
        
        let groupNames = (try? urlConfirm.mustAuth.parsingSetURL().groups) ?? []
        
        tokenService.addToken(token, groupNames: groupNames) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self?.scannerEvent = .success("識別成功！")
                case .failure(let error):
                    let nsError = error as NSError
                    if nsError.domain == "TokenService" && nsError.code == 409,
                       let retryAction = nsError.userInfo["retryAction"] as? () -> Void {
                        self?.scannerEvent = .duplicate(
                            message: "此帳號已存在，請確認是否要繼續添加\n[\(token.issuer)] \(token.name)",
                            primaryAction: {
                                retryAction()
                                self?.scannerEvent = .success("識別成功！")
                            }
                        )
                    } else {
                        self?.scannerEvent = .error(error.localizedDescription)
                    }
                }
            }
        }
    }
    
    private func processMultipleURLs(_ urlStrings: [String]) {
        struct ScannedToken {
            var token: Token
            let groupNames: [String]
        }
        
        let parsedList = urlStrings.compactMap { (urlStr) -> ScannedToken? in
            guard let tokenURLInfo = try? urlStr.mustAuth.parsingSetURL(),
                  let token = Token(customURL: tokenURLInfo.url) else { return nil }
            return ScannedToken(token: token, groupNames: tokenURLInfo.groups)
        }
        
        guard parsedList.count == urlStrings.count else {
            self.scannerEvent = .error("識別多個金鑰時出錯")
            return
        }
        
        let existingPersistentTokens = tokenService.persistentTokens
        
        var duplicateMatches: [(scanned: ScannedToken, existing: PersistentToken)] = []
        for parsed in parsedList {
            if let match = existingPersistentTokens.first(where: {
                $0.token.name == parsed.token.name &&
                $0.token.issuer == parsed.token.issuer &&
                $0.token.isOnTime == parsed.token.isOnTime
            }) {
                duplicateMatches.append((parsed, match))
            }
        }
        
        let hasDuplicates = !duplicateMatches.isEmpty
        
        let performSave: ([ScannedToken], [PersistentToken]?) -> Void = { [weak self] tokensToSave, tokensToReplace in
            guard let self = self else { return }
            
            if let toReplace = tokensToReplace {
                for oldToken in toReplace {
                    try? self.tokenService.deleteToken(oldToken)
                }
            }
            
            for scanned in tokensToSave {
                self.tokenService.addToken(scanned.token, groupNames: scanned.groupNames) { _ in }
            }
            
            let nowDate = Date()
            let shareRecordManager = ShareRecordStoreManager()
            shareRecordManager.addNewRecord(description: "匯入：\(parsedList.count)個驗證碼", date: nowDate)
            for parsed in parsedList {
                RealmDataManager.addMulitpleShareTokenInRecord(
                    account: parsed.token.name,
                    issuer: parsed.token.issuer,
                    groups: parsed.groupNames,
                    time: nowDate
                )
            }
            
            DispatchQueue.main.async {
                self.scannerEvent = .success("已導入\(parsedList.count)個驗證碼")
            }
        }
        
        if !hasDuplicates {
            performSave(parsedList, nil)
        } else {
            var msg = ""
            for (idx, match) in duplicateMatches.enumerated() {
                if idx > 2 {
                    msg += "\n..."
                    break
                }
                if idx > 0 { msg += "\n" }
                msg += "[\(match.scanned.token.issuer)] \(match.scanned.token.name)"
            }
            
            let replaceAction = {
                performSave(parsedList, duplicateMatches.map { $0.existing })
            }
            
            let newAddAction = {
                var updatedList = parsedList
                for (scanned, _) in duplicateMatches {
                    if let index = updatedList.firstIndex(where: { $0.token.name == scanned.token.name && $0.token.issuer == scanned.token.issuer }) {
                        let originalName = updatedList[index].token.name
                        let sameCount = existingPersistentTokens.filter { $0.token.name.hasPrefix(originalName) }.count
                        let suffixName = "\(originalName) \(sameCount + 1)"
                        
                        let newToken = Token(
                            name: suffixName,
                            issuer: updatedList[index].token.issuer,
                            generator: updatedList[index].token.generator
                        )
                        updatedList[index].token = newToken
                    }
                }
                performSave(updatedList, nil)
            }
            
            DispatchQueue.main.async {
                self.scannerEvent = .replaceOrNew(message: msg, replaceAction: replaceAction, newAddAction: newAddAction)
            }
        }
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        context.coordinator.previewLayer = previewLayer
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.previewLayer?.frame = uiView.bounds
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var previewLayer: AVCaptureVideoPreviewLayer?
    }
}

struct ScannerOverlayShape: Shape {
    let cutoutRect: CGRect
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addRect(rect)
        path.addRoundedRect(in: cutoutRect, cornerSize: CGSize(width: 15, height: 15))
        return path
    }
}

struct TokenScannerView: View {
    @StateObject private var viewModel = ScannerViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    @State private var showSuccessAlert = false
    @State private var successAlertMessage = ""
    
    @State private var showErrorAlert = false
    @State private var errorAlertMessage = ""
    
    @State private var showDuplicateAlert = false
    @State private var duplicateAlertMessage = ""
    @State private var duplicateConfirmAction: () -> Void = {}
    
    @State private var showReplaceOrNewAlert = false
    @State private var replaceOrNewAlertMessage = ""
    @State private var replaceAction: () -> Void = {}
    @State private var newAddAction: () -> Void = {}
    
    var body: some View {
        GeometryReader { geometry in
            let screenWidth = geometry.size.width
            let screenHeight = geometry.size.height
            
            let scaleX = screenWidth / 375.0
            let scaleY = screenHeight / 812.0
            
            let cutoutWidth = 293.0 * scaleX
            let cutoutHeight = 293.0 * scaleX
            let cutoutX = (screenWidth - cutoutWidth) / 2
            let cutoutY = 172.0 * scaleY
            let cutoutRect = CGRect(x: cutoutX, y: cutoutY, width: cutoutWidth, height: cutoutHeight)
            
            ZStack {
                CameraPreviewView(session: viewModel.captureSession)
                    .edgesIgnoringSafeArea(.all)
                
                ScannerOverlayShape(cutoutRect: cutoutRect)
                    .fill(Color.black.opacity(0.6), style: FillStyle(eoFill: true))
                    .edgesIgnoringSafeArea(.all)
                
                Image("NoSMS_screen")
                    .resizable()
                    .frame(width: 305 * scaleX, height: 305 * scaleX)
                    .position(x: screenWidth / 2, y: (172 + 293/2) * scaleY)
                
                VStack {
                    Spacer()
                    Text("請將二維碼放入框內，即可自動掃描")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.bottom, 60)
                }
            }
        }
        .navigationBarTitle("掃一掃", displayMode: .inline)
        .onAppear {
            viewModel.startScanning()
        }
        .onDisappear {
            viewModel.stopScanning()
        }
        .onReceive(viewModel.$scannerEvent) { event in
            guard let event = event else { return }
            switch event {
            case .success(let msg):
                successAlertMessage = msg
                showSuccessAlert = true
            case .error(let msg):
                errorAlertMessage = msg
                showErrorAlert = true
            case .duplicate(let msg, let action):
                duplicateAlertMessage = msg
                duplicateConfirmAction = action
                showDuplicateAlert = true
            case .replaceOrNew(let msg, let replace, let newAdd):
                replaceOrNewAlertMessage = msg
                replaceAction = replace
                newAddAction = newAdd
                showReplaceOrNewAlert = true
            }
        }
        // Success Alert
        .alert(isPresented: $showSuccessAlert) {
            Alert(
                title: Text("提示"),
                message: Text(successAlertMessage),
                dismissButton: .default(Text("確認")) {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        // Error Alert
        .background(EmptyView().alert(isPresented: $showErrorAlert) {
            Alert(
                title: Text("錯誤"),
                message: Text(errorAlertMessage),
                dismissButton: .default(Text("確認")) {
                    viewModel.startScanning()
                }
            )
        })
        // Duplicate Confirm Alert
        .background(EmptyView().alert(isPresented: $showDuplicateAlert) {
            Alert(
                title: Text("帳號已存在"),
                message: Text(duplicateAlertMessage),
                primaryButton: .default(Text("確認"), action: duplicateConfirmAction),
                secondaryButton: .cancel(Text("取消")) {
                    viewModel.startScanning()
                }
            )
        })
        // Replace or New Add Alert
        .background(EmptyView().alert(isPresented: $showReplaceOrNewAlert) {
            Alert(
                title: Text("帳號重複"),
                message: Text("是否覆蓋或新建帳號？\n\(replaceOrNewAlertMessage)"),
                primaryButton: .default(Text("覆蓋"), action: replaceAction),
                secondaryButton: .default(Text("新建"), action: newAddAction)
            )
        })
    }
}
