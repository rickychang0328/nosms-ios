import UIKit

enum TFontName:String {
    case    PingFangFontRegular     =   "PingFangSC-Regular",
    PingFangFontMedium      =   "PingFangSC-Medium",
    PingFangFontSemiBold    =   "PingFangSC-Semibold",
    PingFangFontLight       =   "PingFangSC-Light",
    HelveticaNeueRegular    =   "HelveticaNeue",
    HelveticaNeueMedium     =   "HelveticaNeue-Medium",
    HelveticaNeueBold       =   "HelveticaNeue-Bold",
    DINProMedium            =   "DINPro-Medium",
    DINProBold              =   "DINPro-Bold",
    AvenirHeavy             =   "Avenir-Heavy",
    AvenirBlack             =   "Avenir-Black",
    ArialMT                 =   "ArialMT"
}

private var ScreenWidth: CGFloat { UIScreen.main.bounds.size.width }
private var ScreenHeight: CGFloat { UIScreen.main.bounds.size.height }


public func ScaleWidth(at width: CGFloat) -> CGFloat {
    
    return ScreenWidth / 375.0 * width
}

public func ScaleHeight(at height: CGFloat) -> CGFloat {
    
    return ScreenHeight / 812.0 * height
}

extension UIFont {
    class func tFont(fontStyle:TFontName, size:CGFloat) -> UIFont {
        return UIFont(name: fontStyle.rawValue,
                      size: ScaleWidth(at: size)) ?? UIFont.systemFont(ofSize: ScaleWidth(at: size))
    }
    
    class func pingFangRegularFont(size:CGFloat) -> UIFont {
        return tFont(fontStyle: .PingFangFontRegular, size: size)
    }
    
    class func pingFangMediumFont(size:CGFloat) -> UIFont {
        return tFont(fontStyle: .PingFangFontMedium, size: size)
    }
    
    class func pingFangSemiBoldFont(size:CGFloat) -> UIFont {
        return tFont(fontStyle: .PingFangFontSemiBold, size: size)
    }
    
    class func pingFangLightFont(size: CGFloat) -> UIFont {
        return tFont(fontStyle: .PingFangFontLight, size: size)
    }
    
    class func helveticaNeueRegularFont(size:CGFloat) -> UIFont {
        return tFont(fontStyle: .HelveticaNeueRegular, size: size)
    }
    
    class func arialMTFont(size:CGFloat) -> UIFont {
        
        return tFont(fontStyle: .ArialMT, size: size)
    }
    
    class func helveticaNeueMediumFont(size:CGFloat) -> UIFont {
        return tFont(fontStyle: .HelveticaNeueMedium, size: size)
    }
    
    class func helveticaNeueBoldFont(size:CGFloat) -> UIFont {
        return tFont(fontStyle: .HelveticaNeueBold, size: size)
    }
    
    class func dinProMediumBoldFont(size:CGFloat) -> UIFont {
        return tFont(fontStyle: .DINProMedium, size: size)
    }
    
    class func avenirHeavyFont(size:CGFloat) -> UIFont {
        return tFont(fontStyle: .AvenirHeavy, size: size)
    }
    
    class func avenirBlackFont(size:CGFloat) -> UIFont {
        return tFont(fontStyle: .AvenirBlack, size: size)
    }
}
