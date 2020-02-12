//
//  APIClient.swift
//  JsonCoddableUrlSession
//
//  Created by Maksim Vialykh on 08/11/2018.
//  Copyright © 2018 Vialyx. All rights reserved.
//

import Foundation

// TODO: - Move to the separated file Resource.swift
struct Resource {
    let url: URL
    let method: String = "GET"
}
struct PostResource {
    var url:URL
    let method: String = "POST"
    var parameters:[String:Any] = [:]
}
// TODO: - Move to the separated file GenericResult.swift
enum Result<T> {
    case success(T)
    case failure(Error)
}

enum APIClientError: Error {
    case noData
}

// TODO: - Move to the separated file URLRequest+Resource.swift
extension URLRequest {
    
    init(_ resource: Resource) {
        self.init(url: resource.url)
        self.httpMethod = resource.method
    }
    init(_ postResource:PostResource) {
        self.init(url: postResource.url)
        self.httpMethod = postResource.method
        
        var components = URLComponents(url: postResource.url, resolvingAgainstBaseURL: false)!
        let queryItem = postResource.parameters.compactMap({ (key, value) -> URLQueryItem in
            return URLQueryItem(name: key, value: value as? String)
        })
        components.queryItems = queryItem
        let query = components.url!.query
        self.httpBody = Data(query!.utf8)
        
        self.url = components.url
    }
}

final class APIClient {
    
    func post(_ resource: PostResource, result: @escaping ((Result<Data>) -> Void)) {
        let request = URLRequest(resource)
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let `data` = data else {
                result(.failure(APIClientError.noData))
                return
            }
            if let `error` = error {
                result(.failure(error))
                return
            }
            result(.success(data))
        }
        task.resume()
    }
}
