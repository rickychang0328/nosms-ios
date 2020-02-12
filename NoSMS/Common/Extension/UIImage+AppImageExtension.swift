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
    
    static var noSmsDelete: UIImage {
        
        return UIImage(named: "NoSMS_delete") ?? UIImage()
    }
    
    static var noSmsNoInternetConnection: UIImage {
        
        return UIImage(named: "NoSMS_noInternetConnection") ?? UIImage()
    }
    
    static var noSmsSearch: UIImage {
        
        return UIImage(named: "NoSMS_iconSearch") ?? UIImage()
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
    static var noSmsVersionUpdate:UIImage {
        return UIImage(named:"NoSMS_versionupdate") ?? UIImage()
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
    
    
    public class func gif(data: Data) -> UIImage? {
        // Create source from data
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            print("SwiftGif: Source for the image does not exist")
            return nil
        }

        return UIImage.animatedImageWithSource(source)
    }

    public class func gif(url: String) -> UIImage? {
        // Validate URL
        guard let bundleURL = URL(string: url) else {
            print("SwiftGif: This image named \"\(url)\" does not exist")
            return nil
        }

        // Validate data
        guard let imageData = try? Data(contentsOf: bundleURL) else {
            print("SwiftGif: Cannot turn image named \"\(url)\" into NSData")
            return nil
        }

        return gif(data: imageData)
    }

    public class func gif(name: String) -> UIImage? {
        // Check for existance of gif
        guard let bundleURL = Bundle.main
          .url(forResource: name, withExtension: "gif") else {
            print("SwiftGif: This image named \"\(name)\" does not exist")
            return nil
        }

        // Validate data
        guard let imageData = try? Data(contentsOf: bundleURL) else {
            print("SwiftGif: Cannot turn image named \"\(name)\" into NSData")
            return nil
        }

        return gif(data: imageData)
    }

    public class func gif(asset: String) -> UIImage? {
        // Create source from assets catalog
        guard let dataAsset = NSDataAsset(name: asset) else {
            print("SwiftGif: Cannot turn image named \"\(asset)\" into NSDataAsset")
            return nil
        }

        return gif(data: dataAsset.data)
    }

    internal class func delayForImageAtIndex(_ index: Int, source: CGImageSource!) -> Double {
        var delay = 0.1

        // Get dictionaries
        let cfProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil)
        let gifPropertiesPointer = UnsafeMutablePointer<UnsafeRawPointer?>.allocate(capacity: 0)
        defer {
            gifPropertiesPointer.deallocate()
        }
        let unsafePointer = Unmanaged.passUnretained(kCGImagePropertyGIFDictionary).toOpaque()
        if CFDictionaryGetValueIfPresent(cfProperties, unsafePointer, gifPropertiesPointer) == false {
            return delay
        }

        let gifProperties: CFDictionary = unsafeBitCast(gifPropertiesPointer.pointee, to: CFDictionary.self)

        // Get delay time
        var delayObject: AnyObject = unsafeBitCast(
            CFDictionaryGetValue(gifProperties,
                Unmanaged.passUnretained(kCGImagePropertyGIFUnclampedDelayTime).toOpaque()),
            to: AnyObject.self)
        if delayObject.doubleValue == 0 {
            delayObject = unsafeBitCast(CFDictionaryGetValue(gifProperties,
                Unmanaged.passUnretained(kCGImagePropertyGIFDelayTime).toOpaque()), to: AnyObject.self)
        }

        if let delayObject = delayObject as? Double, delayObject > 0 {
            delay = delayObject
        } else {
            delay = 0.1 // Make sure they're not too fast
        }

        return delay
    }

    internal class func gcdForPair(_ lhs: Int?, _ rhs: Int?) -> Int {
        var lhs = lhs
        var rhs = rhs
        // Check if one of them is nil
        if rhs == nil || lhs == nil {
            if rhs != nil {
                return rhs!
            } else if lhs != nil {
                return lhs!
            } else {
                return 0
            }
        }

        // Swap for modulo
        if lhs! < rhs! {
            let ctp = lhs
            lhs = rhs
            rhs = ctp
        }

        // Get greatest common divisor
        var rest: Int
        while true {
            rest = lhs! % rhs!

            if rest == 0 {
                return rhs! // Found it
            } else {
                lhs = rhs
                rhs = rest
            }
        }
    }

    internal class func gcdForArray(_ array: [Int]) -> Int {
        if array.isEmpty {
            return 1
        }

        var gcd = array[0]

        for val in array {
            gcd = UIImage.gcdForPair(val, gcd)
        }

        return gcd
    }

    internal class func animatedImageWithSource(_ source: CGImageSource) -> UIImage? {
        let count = CGImageSourceGetCount(source)
        var images = [CGImage]()
        var delays = [Int]()

        // Fill arrays
        for index in 0..<count {
            // Add image
            if let image = CGImageSourceCreateImageAtIndex(source, index, nil) {
                images.append(image)
            }

            // At it's delay in cs
            let delaySeconds = UIImage.delayForImageAtIndex(Int(index),
                source: source)
            delays.append(Int(delaySeconds * 1000.0)) // Seconds to ms
        }

        // Calculate full duration
        let duration: Int = {
            var sum = 0

            for val: Int in delays {
                sum += val
            }

            return sum
            }()

        // Get frames
        let gcd = gcdForArray(delays)
        var frames = [UIImage]()

        var frame: UIImage
        var frameCount: Int
        for index in 0..<count {
            frame = UIImage(cgImage: images[Int(index)])
            frameCount = Int(delays[Int(index)] / gcd)

            for _ in 0..<frameCount {
                frames.append(frame)
            }
        }

        // Heyhey
        let animation = UIImage.animatedImage(with: frames,
            duration: Double(duration) / 1000.0)

        return animation
    }

}

extension UIImageView {
    
    public func loadGif(name: String) {
           DispatchQueue.global().async {
               let image = UIImage.gif(name: name)
               DispatchQueue.main.async {
                   self.image = image
               }
           }
       }

    public func loadGif(asset: String) {
        DispatchQueue.global().async {
            let image = UIImage.gif(asset: asset)
            DispatchQueue.main.async {
                self.image = image
            }
        }
    }
}
