import UIKit

extension UIImage {
    
    func imageResize (sizeChange:CGSize)-> UIImage{

        let hasAlpha = true
        let scale: CGFloat = 0.0 // Use scale factor of main screen

        UIGraphicsBeginImageContextWithOptions(sizeChange, !hasAlpha, scale)
        self.draw(in: CGRect(origin: CGPoint.zero, size: sizeChange))

        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        return scaledImage!
    }
    
    static var noSmsLegal: UIImage {
        
        return UIImage(named: "NoSMS_legal") ?? UIImage()
    }
    
    static var noSmsRefresh: UIImage {
          
        return UIImage(named: "NoSMS_copy") ?? UIImage()
    }
    
    static var noSmsPrivacy: UIImage {
        
        return UIImage(named: "NoSMS_privacy") ?? UIImage()
    }
    
    static var noSmsService: UIImage {
        
        return UIImage(named: "NoSMS_service") ?? UIImage()
    }
    
    static var noSmsBack: UIImage {
        
        return UIImage(named: "NoSMS_back") ?? UIImage()
    }
    
    static var noSmsKeyin: UIImage {
        
        return UIImage(named: "NoSMS_keyIn") ?? UIImage()
    }
    
    static var noSmsPhoto: UIImage {
        
        return UIImage(named: "NoSMS_photograph") ?? UIImage()
    }
    
    static var noSmsCamera: UIImage {
        
        return UIImage(named: "NoSMS_camera") ?? UIImage()
    }
    
    static var noSmsDoneBlue: UIImage {
          
        return UIImage(named: "NoSMS_doneBlue") ?? UIImage()
    }
    
    static var noSmsUp: UIImage {
        
        return UIImage(named: "NoSMS_up") ?? UIImage()
    }
    
    static var noSmsScreen: UIImage {
           
        return UIImage(named: "NoSMS_screen") ?? UIImage()
    }
    
    static var noSmsdown: UIImage {
           
        return UIImage(named: "NoSMS_down") ?? UIImage()
    }
    
    static var noSmsMore: UIImage {
         
        return UIImage(named: "NoSMS_more") ?? UIImage()
    }
    
    static var noSmsDone: UIImage {
         
        return UIImage(named: "NoSMS_done") ?? UIImage()
    }
    
    
    static var noSmsEdit: UIImage {
           
        return UIImage(named: "NoSMS_pen") ?? UIImage()
    }
    
    static var noSmsAdd: UIImage {
           
        return UIImage(named: "NoSMS_and") ?? UIImage()
    }
    
    static var noSmsLogo: UIImage {
           
        return UIImage(named: "NoSMS_group2") ?? UIImage()
    }
    
    static var noSmsNoSelected: UIImage {
           
        return UIImage(named: "NoSMS_oval") ?? UIImage()
    }
    
    static var noSmsSelectedDelete: UIImage {
              
        return UIImage(named: "NoSMS_group3") ?? UIImage()
    }
    
    static var noSmsMoveCell: UIImage {
              
        return UIImage(named: "NoSMS_move") ?? UIImage()
    }
}
