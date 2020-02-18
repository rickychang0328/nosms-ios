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
    let defaultWebAPI = "https://maapi-dev.azuredigitaltech.com.tw:18443/api/"
    private init() {
        currentWebAPI = getwebAPI()
    }
//    init(apiClient: APIClient) {
//        self.apiClient = apiClient
//    }
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
    func postVersion(_ completion: @escaping ((Result<Version>) -> Void)){
        if let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
//            print("Build Version:\(build)")
            let parameters:[String:Any] = ["platform":"ios","version":build]
            let postURL = RESTAPIURL.VERSION.url!
            let resource = PostResource(url: postURL,parameters: parameters)
            apiClient.post(resource) {[weak self] (result) in
                switch result {
                case .success(let data):
                    do {
                        let str = String(decoding: data, as: UTF8.self)
                        print("jsonData:\(str)")
                        var items = try JSONDecoder().decode(Version.self, from: data)
                        Repository.sharedInstance.version = items
                        items.isNeedUpdate = items.code == 1
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
