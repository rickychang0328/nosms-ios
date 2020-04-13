
import Foundation

extension UserDefaults {
    
    enum Key {
    
        case pastedString
        case faceIDString
        var string: String {
            
            return "pastedString"
        }
        var faceIDString:String {
            return "faceIDString"
        }
    }
    
    func setString(key: UserDefaults.Key, value: String) {
        
        set(value, forKey: key.string)
    }
    
    func getString(key: UserDefaults.Key) -> String? {
        
        return string(forKey: key.string)
    }
}
