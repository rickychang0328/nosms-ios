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
    static var version:Version?
    private let apiClient: APIClient!
    
    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }
    
    
    func postVersion(_ completion: @escaping ((Result<Version>) -> Void)){
        let parameters:[String:Any] = ["platform":"ios","version":"1.1.1"]
        let resource = PostResource(url: URL(string: "https://maapi-dev.azuredigitaltech.com.tw:18443/api/version")!,parameters: parameters)
        apiClient.post(resource) { (result) in
            switch result {
            case .success(let data):
                do {
                    let str = String(decoding: data, as: UTF8.self)
                    print("jsonData:\(str)")
                    let items = try JSONDecoder().decode(Version.self, from: data)
                    Repository.self.version = items
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
