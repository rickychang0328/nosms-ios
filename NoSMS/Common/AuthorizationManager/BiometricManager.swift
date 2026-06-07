import Foundation
import LocalAuthentication

class BiometricManager {
    static let shared = BiometricManager()
    
    private init() {}
    
    enum BiometricType {
        case none
        case touchID
        case faceID
        
        var name: String {
            switch self {
            case .none:
                return "無"
            case .touchID:
                return "指紋"
            case .faceID:
                return "面容ID"
            }
        }
    }
    
    // Checks the biometric authentication hardware support type
    var biometricType: BiometricType {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        
        if #available(iOS 11.0, *) {
            switch context.biometryType {
            case .none:
                return .none
            case .touchID:
                return .touchID
            case .faceID:
                return .faceID
            @unknown default:
                return .none
            }
        } else {
            return .touchID
        }
    }
    
    var isBiometricAvailable: Bool {
        return biometricType != .none
    }
    
    // Performs biometric-only authentication (Face ID or Touch ID) asynchronously
    func authenticate(reason: String) async -> Result<Void, Error> {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .failure(error ?? NSError(domain: "BiometricManager", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "生物識別驗證不可用"
            ]))
        }
        
        return await withCheckedContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authError in
                if success {
                    continuation.resume(returning: .success(()))
                } else {
                    continuation.resume(returning: .failure(authError ?? NSError(domain: "BiometricManager", code: -2, userInfo: [
                        NSLocalizedDescriptionKey: "驗證失敗"
                    ])))
                }
            }
        }
    }
    
    // Performs biometric authentication with system passcode fallback asynchronously
    func authenticateWithPasscodeFallback(reason: String) async -> Result<Void, Error> {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return .failure(error ?? NSError(domain: "BiometricManager", code: -1, userInfo: [
                NSLocalizedDescriptionKey: "本機身份驗證不可用"
            ]))
        }
        
        return await withCheckedContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authError in
                if success {
                    continuation.resume(returning: .success(()))
                } else {
                    continuation.resume(returning: .failure(authError ?? NSError(domain: "BiometricManager", code: -2, userInfo: [
                        NSLocalizedDescriptionKey: "驗證失敗"
                    ])))
                }
            }
        }
    }
}
