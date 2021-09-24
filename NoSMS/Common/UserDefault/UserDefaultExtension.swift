
import Foundation

extension UserDefaults {
    
    enum Key {
    
        case pastedString
        case isFirstSetFaceID
        case faceIDString
        case enterBackgroundTime
        case isAppTerminate
        case gestVerifyPassWord
        case isGestVerifyOpen
        var string: String {
            switch self{
            case .pastedString:
                return "pastedString"
            case .faceIDString:
                return "faceIDString"
            case .enterBackgroundTime:
                return "enterBackgroundTime"
            case .isAppTerminate:
                return "isAppTerminate"
            case .isFirstSetFaceID:
                return "isFirstSetFaceID"
            case .gestVerifyPassWord:
                return "gestVerifyPassWord"
            case .isGestVerifyOpen:
                return "isGestVerifyOpen"
            }
        }
    }
    
    func setString(key: UserDefaults.Key, value: String) {
        
        set(value, forKey: key.string)
    }
    
    func getString(key: UserDefaults.Key) -> String? {
        
        return string(forKey: key.string)
    }
}
