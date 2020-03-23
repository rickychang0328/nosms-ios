
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
    
    private static let _serachTextfieldBackgroundColor: UIColor = .init(red: 153/255, green: 153/255, blue: 153/255, alpha: 0.1)
    
    static var serachTextfieldBackgroundColor: UIColor {
        
        return _serachTextfieldBackgroundColor
    }
    
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
    
    
    private static let color_051_051_051: UIColor = .getColor(red: 51, green: 51, blue: 51, alpha: 1)
    private static let color_098_112_255: UIColor = .getColor(red: 98, green: 112, blue: 255, alpha: 1)
    private static let color_081_095_242: UIColor = .getColor(red: 81, green: 95, blue: 242, alpha: 1)
    private static let color_102_102_102: UIColor = .getColor(red: 102, green: 102, blue: 102, alpha: 1)
    private static let color_237_085_085: UIColor = .getColor(red: 237, green: 85, blue: 85, alpha: 1)
    private static let color_216_216_216: UIColor = .getColor(red: 216, green: 216, blue: 216, alpha: 1)
    private static let color_000_000_000_01: UIColor = .getColor(red: 0, green: 0, blue: 0, alpha: 0.1)
    private static let color_153_153_153_05: UIColor = .getColor(red: 153, green: 153, blue: 153, alpha: 0.5)
    
    private static let color_033_033_033_056: UIColor = .getColor(red: 33, green: 33, blue: 33, alpha: 0.56)
    private static let color_028_028_030: UIColor = .getColor(red: 28, green: 28, blue: 30, alpha: 1)
    private static let color_083_097_250: UIColor = .getColor(red: 83, green: 97, blue: 250, alpha: 1)
    private static let color_255_255_255_06: UIColor = .getColor(red: 255, green: 255, blue: 255, alpha: 0.6)
    private static let color_255_255_255_04: UIColor = .getColor(red: 255, green: 255, blue: 255, alpha: 0.4)
    private static let color_255_255_255_02: UIColor = .getColor(red: 255, green: 255, blue: 255, alpha: 0.2)
    private static let color_000_000_000_08: UIColor = .getColor(red: 0, green: 0, blue: 0, alpha: 0.8)

    static let tokenListAccountColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_255_255_255_04,
                                                                                lightColor: .color_102_102_102)
    static let tokenListPasswordColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_083_097_250,
                                                                                 lightColor: .color_081_095_242)
    static let tokenListBackCardColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_028_028_030,
                                                                                 lightColor: .white)
    static let tokenListIssuerColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .white,
                                                                               lightColor: .color_051_051_051)
    
    static let tokenListHidePasswordColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_255_255_255_06,
                                                                                     lightColor: .color_051_051_051)
    static let tokenListTimerColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_083_097_250, lightColor: .color_081_095_242)
    static let tokenListBackgroundColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_033_033_033_056, lightColor: .white)


    
    static func createUIColorForDarkModeDynmic(darkColor: UIColor, lightColor: UIColor) -> UIColor {
        
        let result: UIColor
        
        if #available(iOS 13, *) {
            
            result = UIColor.init(dynamicProvider: { (traitCollection) -> UIColor in
                
                return traitCollection.userInterfaceStyle == .some(.dark) ? darkColor : lightColor
            })
        } else {
            
            result = lightColor
        }
        
        return result
    }
    
    private static func getColor(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) -> UIColor {
        
        return .init(red: red/255, green: green/255, blue: blue/255, alpha: alpha)
    }
    
    private static let color_250_250_250: UIColor = .getColor(red: 250, green: 250, blue: 250, alpha: 1)
    private static let color_153_153_153_01: UIColor = .getColor(red: 153, green: 153, blue: 153, alpha: 0.1)
    private static let color_043_043_045: UIColor = .getColor(red: 43, green: 43, blue: 45, alpha: 1)
    private static let color_190_192_201_04: UIColor = .getColor(red: 190, green: 192, blue: 201, alpha: 0.4)
    private static let color_046_046_050: UIColor = .getColor(red: 46, green: 46, blue: 50, alpha: 1)
    private static let color_038_038_038: UIColor = .getColor(red: 38, green: 38, blue: 38, alpha: 1)
    private static let color_153_153_153_015: UIColor = .getColor(red: 153, green: 153, blue: 153, alpha: 0.15)
    private static let color_041_044_068: UIColor = .getColor(red: 41, green: 44, blue: 68, alpha: 1)
    private static let color_000_000_000_05: UIColor = .getColor(red: 0, green: 0, blue: 0, alpha: 0.5)
    private static let color_063_063_063: UIColor = .getColor(red: 63, green: 63, blue: 63, alpha: 1)
    private static let color_012_012_012: UIColor = .getColor(red: 12, green: 12, blue: 12, alpha: 1)
    private static let color_239_239_255: UIColor = .getColor(red: 239, green: 239, blue: 255, alpha: 1)
    private static let color_255_255_255_07: UIColor = .getColor(red: 255, green: 255, blue: 255, alpha: 0.7)
    private static let color_255_255_255_05: UIColor = .getColor(red: 255, green: 255, blue: 255, alpha: 0.5)

    
    static let tokenListHidePasswordInEditColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_255_255_255_06, lightColor: .color_000_000_000_01)
    static let tokenListTableViewBackgroundColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .black, lightColor: .color_250_250_250)
    
    static let navColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .navColorDark, lightColor: .navColorLight)
    static let navColorDark: UIColor = .getColor(red: 16.85, green: 16.85, blue: 16.85, alpha: 1)
    static let navColorLight: UIColor = .color_098_112_255
    static let tokenListSearchTextFieldTextColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_255_255_255_06, lightColor: .color_102_102_102)
    
    static let tokenListSearchTextFieldBackgroundColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_028_028_030, lightColor: .color_153_153_153_01)
    static let tokenListUnderLineColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_043_043_045, lightColor: .color_153_153_153_05)
    static let tokenListResetSearchButton: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_083_097_250, lightColor: .color_098_112_255)
    
    static let tokenListWarningPasswordColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .alertCancelButtonColor, lightColor: .color_237_085_085)
    static let tokeListWaringTimerColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .alertCancelButtonColor, lightColor: .color_237_085_085)
    static let tokenListCancelButtonColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_083_097_250, lightColor: .color_098_112_255)
    static let menuTextColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .white, lightColor: .color_051_051_051)
    static let menuUnderLineColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_043_043_045, lightColor: .color_190_192_201_04)
    static let menuBackgroundColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_028_028_030, lightColor: .white)
    static let menuSelectColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_046_046_050, lightColor: .color_153_153_153_01)
    static let mustAuthRedColor: UIColor = .color_237_085_085
    static let webViewReloadButtonColor: UIColor = createUIColorForDarkModeDynmic(darkColor: .white, lightColor: .color_081_095_242)
    static let webViewTextColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_255_255_255_04, lightColor: .color_102_102_102)
    static let webViewBackgroundColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .black, lightColor: .white)
    
    static let tokenListBottomViewBackgroundColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .black, lightColor: .white)
    static let homePageTextColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_255_255_255_07, lightColor: .white)
    static let homePageButtonBroderColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_083_097_250, lightColor: .color_255_255_255_05)
    static let homePageButtonBackgroundColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_083_097_250, lightColor: .clear)
    static let homePageBackgroundColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .black, lightColor: .color_098_112_255)
    
    static let alertsBackgroundColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_038_038_038, lightColor: .color_041_044_068)
    
    static let alertTextColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .white, lightColor: .white)
    static let alertCancelButtonBackgroundColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_153_153_153_015, lightColor: .color_153_153_153_015)
    static let alertCancelButtonTextColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_255_255_255_05, lightColor: .color_255_255_255_05)
    static let alertActionButtonBackgroundColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_083_097_250, lightColor: .color_098_112_255)
    static let alertActionButtonTextColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .white, lightColor: .white)
    
    static let toastBackgroundColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_000_000_000_08, lightColor: .color_000_000_000_05)
    static let toastTextColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .white, lightColor: .white)
    
    static let circleViewBackColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_063_063_063, lightColor: .color_216_216_216)
    static let circleViewNormalColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_083_097_250, lightColor: .color_098_112_255)
    static let circleViewWarningColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_237_085_085, lightColor: .color_237_085_085)
    
    static let circleViewBackColorLight: UIColor = .color_216_216_216
    static let circleViewBackColorDark: UIColor = .color_063_063_063
    static let tokenListBackcardAnimationColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_012_012_012, lightColor: .color_239_239_255)
}
