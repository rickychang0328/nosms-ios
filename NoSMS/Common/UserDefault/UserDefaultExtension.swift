
import Foundation

extension UserDefaults {
    
    enum Key {
    
        case pastedString
        
        var string: String {
            
            return "pastedString"
        }
    }
    
    func setString(key: UserDefaults.Key, value: String) {
        
        set(value, forKey: key.string)
    }
    
    func getString(key: UserDefaults.Key) -> String? {
        
        return string(forKey: key.string)
    }
}
