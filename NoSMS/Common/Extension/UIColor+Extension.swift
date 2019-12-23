
import UIKit

extension UIColor {
    
    private static let _textBlackColor: UIColor = .init(red: 51/255, green: 51/255, blue: 51/255, alpha: 1)
    
    private static let _nameColor: UIColor = .init(red: 102/255, green: 102/255, blue: 102/255, alpha: 1)

    private static let _sercetNormalColor: UIColor = .init(red: 81/255, green: 95/255, blue: 242/255, alpha: 1)
    
    private static let _sercetWarninglColor: UIColor = .init(red: 237/255, green: 85/255, blue: 85/255, alpha: 1)
    
    private static let _issuerColor: UIColor = .init(red: 51/255, green: 51/255, blue: 51/255, alpha: 1)
        
    private static let _countColor: UIColor = .init(red: 98/255, green: 112/255, blue: 255/255, alpha: 1)
    
    private static let _backgroudColor: UIColor = .init(red: 250/255, green: 250/255, blue: 250/255, alpha: 1)
    
    private static let _textFieldUnderLine: UIColor = .init(red: 153/255, green: 153/255, blue: 153/255, alpha: 0.5)
    
    private static let _homePageBorderColor: UIColor = .init(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.5)

    private static let _photoTableViewCellBGColor: UIColor = .init(red: 20/255, green: 18/255, blue: 44/255, alpha: 1)

    private static let _backCoverColor: UIColor = .init(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.6)
    
    private static let _alertBackgroundColor: UIColor = .init(red: 41/255, green: 44/255, blue: 68/255, alpha: 1)
    
    private static let _alertCancelButtonColor: UIColor = .init(red: 153/255, green: 153/255, blue: 153/255, alpha: 0.15)
    
    static var textBlackColor: UIColor {
        
        return _textBlackColor
    }
    
    static var alertBackgroundColor: UIColor {
        
        return _alertBackgroundColor
    }
    
    static var alertCancelButtonColor: UIColor {
        
        return _alertCancelButtonColor
    }
    
    static var alertConfirmButtonColor: UIColor {
        
        return _countColor
    }
    
    static var backCoverColor: UIColor {
        
        return _backCoverColor
    }
    
    static var photoTableViewCellBGColor: UIColor {
        
        return _photoTableViewCellBGColor
    }

    static var homePageBorderColor: UIColor {
        
        return _homePageBorderColor
    }
    
    static var backgroudColor: UIColor {
        
        return _backgroudColor
    }
    static var nameColor: UIColor {
        
        return _nameColor
    }
    
    static var sercetNormalColor: UIColor {
          
        return _sercetNormalColor
    }
      
    static var sercetWarninglColor: UIColor {
          
        return _sercetWarninglColor
    }
    
    static var warninglColor: UIColor {
          
        return _sercetWarninglColor
    }
    
    static var issuerColor: UIColor {
          
        return _issuerColor
    }
    
      
    static var countColor: UIColor {
          
        return _countColor
    }
    
    static var countWarningColor: UIColor {
          
        return _sercetWarninglColor
    }
    
    static var textFieldUnderLineColor: UIColor {
        
        return _textFieldUnderLine
    }
}
