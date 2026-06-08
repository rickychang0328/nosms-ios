import Foundation
import Combine
import LocalAuthentication
import UIKit

class AppLockViewModel: ObservableObject {
    @Published var isLocked: Bool = false
    @Published var isBiometricEnabled: Bool = false
    
    private let biometricManager: BiometricManager
    private let userDefaults: UserDefaults
    private var cancellables = Set<AnyCancellable>()
    private var lastActiveTime: Date = Date()
    private let lockTimeoutInterval: TimeInterval = 300.0 // 5 minutes
    
    init(biometricManager: BiometricManager = .shared, userDefaults: UserDefaults = .standard) {
        self.biometricManager = biometricManager
        self.userDefaults = userDefaults
        
        // Load initial biometric settings status
        let faceIDKey = "faceIDString" // Matches original UserDefaults.Key.faceIDString
        self.isBiometricEnabled = userDefaults.bool(forKey: faceIDKey)
        
        // Listen to active state updates to update setting
        $isBiometricEnabled
            .sink { enabled in
                userDefaults.set(enabled, forKey: faceIDKey)
            }
            .store(in: &cancellables)
            
        // Initial check: if biometrics are enabled, lock app on fresh launch
        if isBiometricEnabled {
            self.isLocked = true
        }
        
        setupLifecycleObservers()
    }
    
    private func setupLifecycleObservers() {
        // Observe entering background to record timestamp
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.lastActiveTime = Date()
            }
            .store(in: &cancellables)
            
        // Observe entering foreground to calculate background duration
        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.checkTimeoutLock()
            }
            .store(in: &cancellables)
    }
    
    private func checkTimeoutLock() {
        guard isBiometricEnabled else { return }
        
        let elapsed = Date().timeIntervalSince(lastActiveTime)
        if elapsed >= lockTimeoutInterval {
            self.isLocked = true
            // Automatically trigger biometric authentication when locked
            Task {
                await authenticateUser()
            }
        }
    }
    
    func authenticateUser() async {
        guard isBiometricEnabled && isLocked else { return }
        
        let reason = biometricManager.biometricType == .faceID ? "請使用面容ID解鎖" : "請使用指紋解鎖"
        let result = await biometricManager.authenticate(reason: reason)
        
        await MainActor.run {
            switch result {
            case .success:
                self.isLocked = false
            case .failure(let error as LAError):
                // If biometrics fail repeatedly or user cancels, fallback to passcode
                if error.code != .userCancel && error.code != .systemCancel {
                    Task {
                        await authenticateWithPasscodeFallback()
                    }
                }
            case .failure:
                break
            }
        }
    }
    
    private func authenticateWithPasscodeFallback() async {
        let reason = "驗證多次失敗，請輸入手機密碼解鎖"
        let result = await biometricManager.authenticateWithPasscodeFallback(reason: reason)
        
        await MainActor.run {
            switch result {
            case .success:
                self.isLocked = false
            case .failure:
                break
            }
        }
    }
}
