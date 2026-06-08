import Foundation
import Combine

class GestureLockViewModel: ObservableObject {
    @Published var isGestureOpen: Bool = false
    @Published var setupStateMessage: String = "請繪製手勢密碼"
    
    // Setting state machine
    enum SetupPhase {
        case firstDraw
        case confirmDraw(firstPattern: String)
        case completed
    }
    
    @Published var currentSetupPhase: SetupPhase = .firstDraw
    
    private let userDefaults: UserDefaults
    private let kIsGestVerifyOpen = "isGestVerifyOpen"
    private let kGestVerifyPassWord = "gestVerifyPassWord"
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.isGestureOpen = userDefaults.bool(forKey: kIsGestVerifyOpen)
    }
    
    var savedPassword: String? {
        return userDefaults.string(forKey: kGestVerifyPassWord)
    }
    
    // Validates a drawn pattern against the saved password
    func validate(pattern: String) -> Bool {
        guard isGestureOpen, let saved = savedPassword else { return false }
        return pattern == saved
    }
    
    // Process drawing logic during password setup
    func processSetupDraw(pattern: String) -> Bool {
        guard pattern.count >= 4 else {
            setupStateMessage = "最少需要連接4個點"
            return false
        }
        
        switch currentSetupPhase {
        case .firstDraw:
            currentSetupPhase = .confirmDraw(firstPattern: pattern)
            setupStateMessage = "請再次繪製以確認"
            return true
            
        case .confirmDraw(let firstPattern):
            if pattern == firstPattern {
                saveNewPassword(password: pattern)
                currentSetupPhase = .completed
                setupStateMessage = "手勢解鎖已開啟"
                return true
            } else {
                setupStateMessage = "兩次繪製不一致，請重新繪製"
                currentSetupPhase = .firstDraw
                return false
            }
            
        case .completed:
            return true
        }
    }
    
    func resetSetupState() {
        currentSetupPhase = .firstDraw
        setupStateMessage = "請繪製手勢密碼"
    }
    
    func disableGestureLock() {
        userDefaults.set(false, forKey: kIsGestVerifyOpen)
        userDefaults.set("", forKey: kGestVerifyPassWord)
        isGestureOpen = false
        resetSetupState()
    }
    
    private func saveNewPassword(password: String) {
        userDefaults.set(password, forKey: kGestVerifyPassWord)
        userDefaults.set(true, forKey: kIsGestVerifyOpen)
        isGestureOpen = true
    }
}
