//
//  Repository.swift
//  JsonCoddableUrlSession
//
//  Created by Maksim Vialykh on 08/11/2018.
//  Copyright © 2018 Vialyx. All rights reserved.
//

import Foundation
import UIKit

enum RESTAPIURL:String {
    case VERSION =  "version"
    
    var urlString:String {
        return Repository.sharedInstance.getCurrentAPI() + self.rawValue
    }
    var url:URL? {
        return URL(string: urlString)!
    }
}
// MARK: - Version
struct Version: Codable {
    let code: Int
    var isNeedUpdate:Bool?
    let info: String
    let domain: [String]
    let version_info: VersionInfo?
}

// MARK: - VersionInfo
struct VersionInfo: Codable {
    let platform, version: String
    let url: String
    let notes: [String]
}
final class Repository {
    var version:Version?
    private let apiClient: APIClient = APIClient()
    static let sharedInstance = Repository()
    private var currentWebAPI = ""
    let defaultWebAPI = "https://maapi-dev.azuredigitaltech.com.tw:18443/api/"
    private init() {
        currentWebAPI = getwebAPI()
    }
//    init(apiClient: APIClient) {
//        self.apiClient = apiClient
//    }
    private var webViewURL = "https://mustauth.com/"
    func getWebViewURL()->String {
        return webViewURL
    }
    private func getwebAPI()->String{
        if let webAPI = Bundle.main.object(forInfoDictionaryKey: "webAPI") as? String {
            return webAPI
        }else{
            return defaultWebAPI
        }
    }
    func getCurrentAPI()->String {
        return currentWebAPI
    }
    
    fileprivate func composeURL(_ APIDomainPort: String, _ webViewDomainProtocol: String, _ defaultFirstAPIDomain: String, _ items: Version) {
        if APIDomainPort.isEmpty {
            self.currentWebAPI = "\(webViewDomainProtocol)://\(defaultFirstAPIDomain).\(items.domain[0])/api/"
        }else{
            self.currentWebAPI = "\(String(describing: webViewDomainProtocol))://\(defaultFirstAPIDomain).\(items.domain[0]):\(APIDomainPort)/api/"
        }
        
        if items.domain.count > 1 {
            self.webViewURL = "\(webViewDomainProtocol)://\(items.domain[1].replacingOccurrences(of: "“", with: "").replacingOccurrences(of: "”", with: ""))/"
        }else if items.domain.count == 1{
            self.webViewURL = "\(webViewDomainProtocol)://\(items.domain[0].replacingOccurrences(of: "“", with: "").replacingOccurrences(of: "”", with: ""))/"
        }
//        print("current url:\(self.currentWebAPI),webview url:\(self.webViewURL)")
    }
    
    func postVersion(_ completion: @escaping ((Result<Version>) -> Void)){
        if let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
//            print("Build Version:\(build)")
//            print("uuid:\(UIDevice.current.identifierForVendor?.uuidString),model:\(UIDevice.current.modelName.lowercased().replacingOccurrences(of: " ", with: "")),os_version:\(UIDevice.current.systemVersion)")
            let parameters:[String:Any] = ["platform":"ios","version":build,"mid":UIDevice.current.vkKeychainIDFV()?.lowercased() ?? "","brand":"apple","model":UIDevice.current.modelName.lowercased().replacingOccurrences(of: " ", with: ""),"os_version":UIDevice.current.systemVersion]
//            print("IDFV:\(UIDevice.current.vkKeychainIDFV()?.lowercased())")
            let postURL = RESTAPIURL.VERSION.url!
            let resource = PostResource(url: postURL,parameters: parameters)
            apiClient.post(resource) {[weak self] (result) in
                guard let self = self else{return}
                switch result {
                case .success(let data):
                    do {
                        let webViewDomainProtocol = Bundle.main.object(forInfoDictionaryKey: "webViewDomainProtocol") as? String ?? ""
                        let defaultFirstAPIDomain = Bundle.main.object(forInfoDictionaryKey: "defaultFirstAPIDomain") as? String ?? ""
                        let APIDomainPort = Bundle.main.object(forInfoDictionaryKey: "APIDomainPort") as? String ?? ""
                        let str = String(decoding: data, as: UTF8.self)
                        print("jsonData:\(str)")
                        var items = try JSONDecoder().decode(Version.self, from: data)
                        Repository.sharedInstance.version = items
                        items.isNeedUpdate = items.code == 1
                        Repository.sharedInstance.version?.isNeedUpdate = items.isNeedUpdate
                        if items.domain.count > 0 && !items.domain[0].isEmpty{
                            self.composeURL(APIDomainPort, webViewDomainProtocol, defaultFirstAPIDomain, items)
                        }
                        completion(.success(items))
                    } catch {
                        completion(.failure(error))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
}
//https://stackoverflow.com/questions/11197509/how-to-get-device-make-and-model-on-ios
extension UIDevice {
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}
