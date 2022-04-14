//
//  NetworkEngine.swift
//
//  Created by Jonathan Rivera on 01/04/22.
//  Copyright © 2022 Jonathan Rivera. All rights reserved.
//

import Foundation
import UIKit

public struct GenericResponseSuccess: Decodable {
    var response = true
}

struct ErrorAPI: Codable {
    var message: String?
    var codeUser: String?
    var codeApi: String?
}

public class NetworkEngine {
    private var endpoint: Endpoint
    private var path: String
    private var parameters: [URLQueryItem]?
    private var method: HttpMethod
    private var urlSession: URLSession
    private let genericErrorCode = "E0001"
    private var debugMode: Bool
    
    public init(path: String, parameters: [URLQueryItem]?, method: HttpMethod = .get, urlSession: URLSession = URLSession.shared, endpoint: Endpoint, debugMode: Bool = true) {
        self.path = path
        self.parameters = parameters
        self.method = method
        self.urlSession = urlSession
        self.endpoint = endpoint
        self.debugMode = debugMode
    }
    
    public enum HttpMethod: String {
        case get
        case post
        case put
    }
    
    public func request<T:Decodable>(with data: [String:Any]? = nil, completion: @escaping (Result<T?, Error>) -> ()) {
        
        DispatchQueue.global(qos: .utility).async {
            let dataTask = self.urlSession.dataTask(with: self.createURLRequest(with: data)!) { [self] data, response, error in
                guard error == nil else {
                    DispatchQueue.main.async {
                        let error = NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: genericErrorCode])
                        completion(.failure(error))
                    }
                    return
                }
                
                if debugMode {
                    if let data = data, let json = self.nsdataToJSON(data) {
                        print(json)
                    }
                }
                
                let httpResponse = response as? HTTPURLResponse
                
                guard response != nil, let data = data else { return }
                DispatchQueue.main.async {
                    if httpResponse?.statusCode ?? 400 >= 400 {
                        let error = try? JSONDecoder().decode(ErrorAPI.self, from: data)
                        
                        let errorAPI = NSError(domain: "", code: 200, userInfo: [NSLocalizedDescriptionKey: error?.codeUser ?? (genericErrorCode) as Any])
                        
                        completion(.failure(errorAPI))
                    }else {
                        if let objectResponse = try? JSONDecoder().decode(T.self, from: data) {
                            completion(.success(objectResponse))
                        }else {
                            completion(.success(nil))
                        }
                    }
                }
            }
            dataTask.resume()
        }
    }
    
    private func createURLRequest(with dctRequest: [String: Any]? = nil) -> URLRequest? {
        guard let url = createComponents().url else { return nil }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        urlRequest.allHTTPHeaderFields = endpoint.headers
        
        if method == .post {
            urlRequest.httpBody = getHTTPBody(with: dctRequest)
        }
        
        return urlRequest
    }
    
    private func createComponents() -> URLComponents {
        var components = URLComponents()
        components.scheme = endpoint.scheme
        components.host = endpoint.baseURL
        components.path = endpoint.environment + path
        components.queryItems = parameters
        
        return components
    }
    
    private func getHTTPBody(with dctRequest: [String: Any]?) -> Data? {
        if let dctRequest = dctRequest {
            var bodyData = Data()
            guard let json = try? JSONSerialization.data(withJSONObject: dctRequest, options: .prettyPrinted) else { return nil }
            bodyData.append(json)
            return bodyData
        }
        
        return nil
    }
    
    private func nsdataToJSON(_ data: Data) -> [String:AnyObject]? {
        do {
            return try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String:AnyObject]
        } catch  _{
            print("dataString = \(NSString(data: data, encoding:String.Encoding.utf8.rawValue)!)")
            return nil
        }
    }
}
