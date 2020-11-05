
import UIKit

extension UIColor {
  
    private static func createUIColorForDarkModeDynmic(darkColor: UIColor, lightColor: UIColor) -> UIColor {
        
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
    
    static func getColor(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) -> UIColor {
        
        return .init(red: red/255, green: green/255, blue: blue/255, alpha: alpha)
    }
    
    private static let color_051_051_051: UIColor = .getColor(red: 51, green: 51, blue: 51, alpha: 1)
    private static let color_098_112_255: UIColor = .getColor(red: 98, green: 112, blue: 255, alpha: 1)
    private static let color_081_095_242: UIColor = .getColor(red: 81, green: 95, blue: 242, alpha: 1)
    private static let color_102_102_102: UIColor = .getColor(red: 102, green: 102, blue: 102, alpha: 1)
    private static let color_237_085_085: UIColor = .getColor(red: 237, green: 85, blue: 85, alpha: 1)
    private static let color_216_216_216: UIColor = .getColor(red: 216, green: 216, blue: 216, alpha: 1)
    private static let color_000_000_000_01: UIColor = .getColor(red: 0, green: 0, blue: 0, alpha: 0.1)
    private static let color_000_000_000_04: UIColor = .getColor(red: 0, green: 0, blue: 0, alpha: 0.4)
    private static let color_153_153_153_05: UIColor = .getColor(red: 153, green: 153, blue: 153, alpha: 0.5)
    private static let color_190_192_201_02: UIColor = .getColor(red: 190, green: 192, blue: 201, alpha: 0.2)
    private static let color_190_192_201_04: UIColor = .getColor(red: 190, green: 192, blue: 201, alpha: 0.4)
    private static let color_033_033_033_056: UIColor = .getColor(red: 33, green: 33, blue: 33, alpha: 0.56)
    private static let color_028_028_030: UIColor = .getColor(red: 28, green: 28, blue: 30, alpha: 1)
    private static let color_083_097_250: UIColor = .getColor(red: 83, green: 97, blue: 250, alpha: 1)
    private static let color_255_255_255_06: UIColor = .getColor(red: 255, green: 255, blue: 255, alpha: 0.6)
    private static let color_255_255_255_04: UIColor = .getColor(red: 255, green: 255, blue: 255, alpha: 0.4)
    private static let color_255_255_255_02: UIColor = .getColor(red: 255, green: 255, blue: 255, alpha: 0.2)
    private static let color_000_000_000_08: UIColor = .getColor(red: 0, green: 0, blue: 0, alpha: 0.8)
    private static let color_250_250_250: UIColor = .getColor(red: 250, green: 250, blue: 250, alpha: 1)
    private static let color_153_153_153_01: UIColor = .getColor(red: 153, green: 153, blue: 153, alpha: 0.1)
    private static let color_043_043_045: UIColor = .getColor(red: 43, green: 43, blue: 45, alpha: 1)
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
    private static let color_020_018_044: UIColor = .getColor(red: 20, green: 18, blue: 44, alpha: 1)
    private static let color_036_205_132: UIColor = .getColor(red: 36, green: 205, blue: 132, alpha: 1)
    private static let color_050_230_152: UIColor = .getColor(red: 50, green: 230, blue: 152, alpha: 1)

    private static let color_136_136_136: UIColor = .getColor(red: 136, green: 136, blue: 136, alpha: 1)
    private static let color_249_249_249: UIColor = .getColor(red: 249, green: 249, blue: 249, alpha: 1)
    private static let color_057_060_080: UIColor = .getColor(red: 57, green: 60, blue: 80, alpha: 1)
    private static let color_153_153_153_002: UIColor = .getColor(red: 153, green: 153, blue: 153, alpha: 0.02)
    private static let color_153_153_153_003: UIColor = .getColor(red: 153, green: 153, blue: 153, alpha: 0.03)
    private static let color_240_240_240: UIColor = .getColor(red: 240, green: 240, blue: 240, alpha: 1)
    private static let color_239_239_239: UIColor = .getColor(red: 239, green: 239, blue: 255, alpha: 1)
    private static let color_026_026_028: UIColor = .getColor(red: 26, green: 26, blue: 28, alpha: 1)

    
    static let mustAuthRedColor: UIColor = .color_237_085_085
    
    //MARK: TokenList
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
    static let tokenListTimerColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_083_097_250,
                                                                              lightColor: .color_098_112_255)
    static let tokenListBackgroundColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_033_033_033_056,
                                                                                   lightColor: .color_249_249_249)
    static let otpshareRecordCellLineColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .black,
                                                                                      lightColor: .color_249_249_249)
    static let optShareBackgroundColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .black,
                                                                                      lightColor: .color_249_249_249)
    static let optShareRecordBackgroundColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .black,
                                                                                         lightColor: .color_249_249_249)
    static let tokenListHidePasswordInEditColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_255_255_255_06,
                                                                                           lightColor: .color_000_000_000_01)
    static let tokenListTableViewBackgroundColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .black,
                                                                                            lightColor: .color_240_240_240)
    static let tokenListSearchTextFieldTextColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_255_255_255_06,
                                                                                            lightColor: .color_102_102_102)
    
    static let tokenListSearchTextFieldBackgroundColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_028_028_030,
                                                                                                  lightColor: .color_153_153_153_01)
    static let tokenListUnderLineColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_043_043_045,
                                                                                  lightColor: .color_153_153_153_05)
    static let tokenListResetSearchButton: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_083_097_250,
                                                                                     lightColor: .color_098_112_255)
    
    static let tokenListWarningPasswordColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_237_085_085,
                                                                                        lightColor: .color_237_085_085)
    static let tokeListWaringTimerColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_237_085_085,
                                                                                   lightColor: .color_237_085_085)
    static let tokenListCancelButtonColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_083_097_250,
                                                                                     lightColor: .color_098_112_255)
    static let tokenListBottomViewBackgroundColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .black,
                                                                                             lightColor: .white)
    static let tokenListBackcardAnimationColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_012_012_012,
                                                                                          lightColor: .color_239_239_255)
    static let tokenListCellTextFieldColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_255_255_255_04,
                                                                                      lightColor: .color_102_102_102)
    static let tokenListCellTextFieldUnderLineColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_043_043_045,
                                                                                               lightColor: .color_153_153_153_05)
    static let tokenListCellSwipeBackgroundColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_083_097_250, lightColor: .color_098_112_255)
    static let tokenListCellBackCardPinColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_028_028_030, lightColor: .color_249_249_249)
    
    
    
    //MARK: ManuallyTOTP
    static let manuallyTOTPBackgroundColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .black,
                                                                                      lightColor: .white)
    static let manuallyTOTPTitleColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .white,
                                                                                 lightColor: .color_051_051_051)
    static let manuallyTOTPTextFieldColor: UIColor = .createUIColorForDarkModeDynmic(darkColor:.color_255_255_255_04,
                                                                                     lightColor: .color_051_051_051)
    static let manuallyTOTPTextFieldUnderLineColor: UIColor = .createUIColorForDarkModeDynmic(darkColor:.color_043_043_045,
                                                                                              lightColor:.color_153_153_153_05)
    static let manuallyTOTPSwitchColor: UIColor = .createUIColorForDarkModeDynmic(darkColor:.color_050_230_152,
                                                                                  lightColor:.color_036_205_132)

    
    
    //MARK: PhotoCheck
    static let photoCheckViewBackgroundColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .black,
                                                                                        lightColor: .color_250_250_250)
    static let photoCheckTableViewCellBackgroundColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_028_028_030,
                                                                                                 lightColor: .color_020_018_044)
    static let photoChoseCoverColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_000_000_000_04,
                                                                               lightColor: .color_000_000_000_04)
    static let photoCheckCountLabelColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_255_255_255_05,
                                                                                    lightColor: .color_255_255_255_05)
    
    static let photoCheckAuthLabelColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .white,
                                                                                    lightColor: .color_051_051_051)
    static let photoCheckButtonTextAndBackgroundColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_098_112_255,
                                                                                                 lightColor: .color_098_112_255)


    
    //MARK: ChoseToAddToken
    static let choseToAddTokenViewBackgroundColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_046_046_050,
                                                                                             lightColor: .white)
    static let choseToAddTokenLineColor:UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_190_192_201_02,
                                                                                  lightColor: .color_190_192_201_04)
    static let choseToAddLabelTitleTextColor:UIColor = .createUIColorForDarkModeDynmic(darkColor: .white,
                                                                                       lightColor: .color_051_051_051)
    
    //MARK: Navigation
    static let navigationColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .navColorDark,
                                                                          lightColor: .navColorLight)
    static let navigationOTPColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: getColor(red: 33, green: 33, blue: 33, alpha: 0.56),
                                                                             lightColor: .navColorLight)
    static let navColorDark: UIColor = .getColor(red: 16.85, green: 16.85, blue: 16.85, alpha: 1)
    static let navColorLight: UIColor = .color_098_112_255
    
    //MARK: Menu
    static let menuTextColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .white,
                                                                        lightColor: .color_051_051_051)
    static let menuUnderLineColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_043_043_045,
                                                                             lightColor: .color_190_192_201_04)
    static let menuBackgroundColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_028_028_030,
                                                                              lightColor: .white)
    static let menuSelectColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_046_046_050,
                                                                          lightColor: .color_153_153_153_01)
    
    
    //MARK: WebView
    static let webViewReloadButtonColor: UIColor = createUIColorForDarkModeDynmic(darkColor: .white,
                                                                                  lightColor: .color_081_095_242)
    static let webViewTextColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_255_255_255_04,
                                                                           lightColor: .color_102_102_102)
    static let webViewBackgroundColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .black,
                                                                                 lightColor: .white)
    
    
    //MARK: HomePage
    static let homePageTextColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_255_255_255_07,
                                                                            lightColor: .white)
    static let homePageButtonBroderColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_083_097_250,
                                                                                    lightColor: .color_255_255_255_05)
    static let homePageButtonBackgroundColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_083_097_250,
                                                                                        lightColor: .clear)
    static let homePageBackgroundColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .black,
                                                                                  lightColor: .color_098_112_255)
    
    
    //MARK: Alert
    static let alertsBackgroundColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_038_038_038,
                                                                                lightColor: .color_041_044_068)
    static let alertTextColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .white,
                                                                         lightColor: .white)
    static let alertScanTextColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .white,
                                                                            lightColor: .getColor(red: 51, green: 51, blue: 51, alpha: 1))
    static let alertCancelButtonBackgroundColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_153_153_153_015,
                                                                                           lightColor: .color_153_153_153_015)
    static let alertCancelButtonTextColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_255_255_255_05,
                                                                                     lightColor: .color_255_255_255_05)
    static let alertActionButtonBackgroundColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_083_097_250,
                                                                                           lightColor: .color_098_112_255)
    static let alertActionButtonTextColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .white,
                                                                                     lightColor: .white)
    static let exportOTPDisableTextColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .getColor(red: 153, green: 153, blue: 153, alpha: 1),
                                                                                    lightColor: .getColor(red: 153, green: 153, blue: 153, alpha: 0.5))
    static let exportOTPEnableTextColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .getColor(red: 105, green: 128, blue: 252, alpha: 1),
    lightColor: .getColor(red: 98, green: 112, blue: 255, alpha: 1))
    static let alertStreetActionButtonTextColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_237_085_085,
    lightColor: .color_237_085_085)
    static let alertStreetCancelButtonBackGroundColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_028_028_030, lightColor: .color_057_060_080)
    static let alertStreetCancelButtonTextColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_153_153_153_003, lightColor: .color_255_255_255_05)
    static let alertStreetUnderLineColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_190_192_201_04, lightColor: .color_190_192_201_04)


    
    
    //MARK: Toast
    static let toastBackgroundColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_000_000_000_08,
                                                                               lightColor: .color_000_000_000_05)
    static let toastTextColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .white,
                                                                         lightColor: .white)
    
    
    //MARK: CircleView
    static let circleViewBackColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_063_063_063,
                                                                              lightColor: .color_216_216_216)
    static let circleViewNormalColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_083_097_250,
                                                                                lightColor: .color_098_112_255)
    static let circleViewWarningColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_237_085_085,
                                                                                 lightColor: .color_237_085_085)
    static let circleViewBackColorLight: UIColor = .color_216_216_216
    static let circleViewBackColorDark: UIColor = .color_063_063_063
    

    //MARK: VersionUpdate
    static let versionUpdateButtonBorderColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_255_255_255_05,
                                                                                         lightColor: .color_255_255_255_05)
    static let versionUpdateBackgroundColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .black,
                                                                                       lightColor: .color_098_112_255)
    
    
    //MARK: Screen
    static let screenCoverColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_000_000_000_04,
                                                                           lightColor: .color_000_000_000_04)

    
    //MARK: DissmissViewCover
    static let dissmissCoverColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_000_000_000_05,
                                                                             lightColor: .color_000_000_000_04)


    //MARK: GroupView
    static let groupBackCardColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_028_028_030, lightColor: .white)
    static let groupHeaderTitleColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_102_102_102, lightColor: .color_102_102_102)
    static let groupCellTitleColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .white, lightColor: .color_051_051_051)
    
    //MARK: GroupEditView
    static let groupEditTextFieldTextColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_255_255_255_06, lightColor: .color_051_051_051)
    static let groupEditAddCodeButtonColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_083_097_250, lightColor: .color_098_112_255)
    static let groupEditTextFieldBackGroundColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_153_153_153_01, lightColor: .white)
    static let groupEditAddCodeButtonBackGroundColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_153_153_153_01, lightColor: .white)
    static let groupCellBackCardColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_028_028_030, lightColor: .white)
    static let groupAddCodeVCBackGroundColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_033_033_033_056, lightColor: .color_249_249_249)
    static let groupEditCellDeleteActionColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_237_085_085, lightColor: .color_237_085_085)

    
    //MARK: CustomSegmentControl
    static let customSegmentControlEnableTextColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_083_097_250, lightColor: .color_098_112_255)
    static let customSegmentControlDisnableTextColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_136_136_136, lightColor: .color_136_136_136)
    static let customSegmentControlUnderLineColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_083_097_250, lightColor: .color_098_112_255)
    


    //MARK: FaceIDSetting
    static let faceIDSettingBackgroundColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_026_026_028,
    lightColor: .white)
    static let faceIDSettingVCBackgroundColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .black,
    lightColor: .color_239_239_239)
    static let faceIDSettingTextColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .white,
                                                                                     lightColor: .color_051_051_051)
    static let faceIDSettingHeaderTextColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .color_255_255_255_06, lightColor: .color_102_102_102)
    static let otpShareReceiveButtonTextColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .white, lightColor: .getColor(red: 51, green: 51, blue: 51, alpha: 1))
    static let otpShareReceiveButtonColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .getColor(red: 26   , green: 26, blue: 28, alpha: 1), lightColor: .white)
    static let otpShareReceiveButtonHintColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .getColor(red: 136, green: 136, blue: 138, alpha: 1), lightColor: .getColor(red: 136, green: 136, blue: 138, alpha: 1))
    static let otpScanHintColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .getColor(red: 0, green: 0, blue: 0, alpha: 0.8), lightColor: .getColor(red: 255, green: 255, blue: 255, alpha: 0.8))
    static let otpScanHintTextColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .white, lightColor: .getColor(red: 51, green: 51, blue: 51, alpha: 1))
    static let otpShareSearchTextColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .white, lightColor: .getColor(red: 136, green: 136, blue: 136, alpha: 1))
    static let alertScanViewColor: UIColor = .createUIColorForDarkModeDynmic(darkColor: .getColor(red: 0, green: 0, blue: 0, alpha: 0.95), lightColor: .white)
}
