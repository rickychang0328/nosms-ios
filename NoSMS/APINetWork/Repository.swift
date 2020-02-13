//
//  Repository.swift
//  JsonCoddableUrlSession
//
//  Created by Maksim Vialykh on 08/11/2018.
//  Copyright © 2018 Vialyx. All rights reserved.
//

import Foundation

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
    private init() {
        
    }
//    init(apiClient: APIClient) {
//        self.apiClient = apiClient
//    }
    
    
    func postVersion(_ completion: @escaping ((Result<Version>) -> Void)){
        if let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String {
            let parameters:[String:Any] = ["platform":"ios","version":build]
            let resource = PostResource(url: URL(string: "https://maapi-dev.azuredigitaltech.com.tw:18443/api/version")!,parameters: parameters)
            apiClient.post(resource) { (result) in
                switch result {
                case .success(let data):
                    do {
                        let str = String(decoding: data, as: UTF8.self)
                        print("jsonData:\(str)")
                        var items = try JSONDecoder().decode(Version.self, from: data)
                        Repository.sharedInstance.version = items
                        items.isNeedUpdate = items.code == 1
                        Repository.sharedInstance.version?.isNeedUpdate = items.isNeedUpdate
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
