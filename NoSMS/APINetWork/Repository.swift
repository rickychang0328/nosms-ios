//
//  Repository.swift
//  JsonCoddableUrlSession
//
//  Created by Maksim Vialykh on 08/11/2018.
//  Copyright © 2018 Vialyx. All rights reserved.
//

import Foundation
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
    private var currentWebViewDomain = ""
    private let defaultAPI = "https://maapi-dev.azuredigitaltech.com.tw:18443/api/"
    let defaultWebAPI = "https://maapi-dev.azuredigitaltech.com.tw:18443/api/"
    private init() {
        currentWebAPI = getDefaultwebAPI()
    }
    func getCurrentAPI()-> String {
        return currentWebAPI
    }
//    init(apiClient: APIClient) {
//        self.apiClient = apiClient
//    }
    private func getDefaultwebAPI()->String{
        if let webAPI = Bundle.main.object(forInfoDictionaryKey: "webAPI") as? String {
            return webAPI
        }else{
            return defaultAPI
        }
    }
    private func getWebAPI(domain:String)->String {
        if let firstAPIDomain = Bundle.main.object(forInfoDictionaryKey: "defaultFirstAPIDomain") as? String,let apiDomainProtocol = Bundle.main.object(forInfoDictionaryKey: "apiDomainProtocol") as? String,let APIDomainPort = Bundle.main.object(forInfoDictionaryKey: "APIDomainPort") as? String {
            if !APIDomainPort.isEmpty {
                return "\(apiDomainProtocol)://\(firstAPIDomain).\(domain):\(APIDomainPort)/api/"
            } else {
                return "\(apiDomainProtocol)://\(firstAPIDomain).\(domain)/api/"
            }
            
        }else{
            return "https://maapi-dev.azuredigitaltech.com.tw:18443/api/"
        }
    }
    private func getWebViewDomain(domain:String)->String {
        if let firstWebViewDomain = Bundle.main.object(forInfoDictionaryKey: "defaultFirstWebViewDomain") as? String,let webViewDomainProtocol = Bundle.main.object(forInfoDictionaryKey: "webViewDomainProtocol") as? String,let webViewDomainPort = Bundle.main.object(forInfoDictionaryKey: "WebViewDomainPort") as? String {
            if !webViewDomainPort.isEmpty {
                return "\(webViewDomainProtocol)://\(firstWebViewDomain).\(domain):\(webViewDomainPort)/"
            } else {
                return "\(webViewDomainProtocol)://\(firstWebViewDomain).\(domain)/"
            }
            
        }else{
            return defaultWebAPI
        }
    }
   
    func postVersion(_ completion: @escaping ((Result<Version>) -> Void)){
        if let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
//            print("Build Version:\(build)")
            let parameters:[String : Any] = ["platform":"ios","version":String(describing:build)]
            let postURL = RESTAPIURL.VERSION.url!
            let resource = PostResource(url: postURL,parameters: parameters)
            apiClient.post(resource) {[weak self] (result) in
                switch result {
                case .success(let data):
                    do {
                        let str = String(decoding: data, as: UTF8.self)
                        print("jsonData:\(str)")
                        var items = try JSONDecoder().decode(Version.self, from: data)
                        self?.version = items
                        if items.domain.count > 0 && !items.domain[0].isEmpty{
//                            print("compose webapi:\(self?.getWebAPI(domain: items.domain[0]))")
                            self?.currentWebAPI = self?.getWebAPI(domain: items.domain[0]) ?? self!.getDefaultwebAPI()
                            self?.currentWebViewDomain = self?.getWebViewDomain(domain: items.domain[0]) ?? ""
                        }

                        items.isNeedUpdate = items.code == 1
                        self?.version?.isNeedUpdate = items.isNeedUpdate
                        Repository.sharedInstance.version?.isNeedUpdate = items.isNeedUpdate
//                        if items.domain.count > 0 && !items.domain[0].isEmpty{
//
//                            self?.currentWebAPI = "https://api.\(items.domain[0])/api/"
//                        }
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
