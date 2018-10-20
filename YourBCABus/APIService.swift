//
//  APIService.swift
//  YourBCABus
//
//  Created by Anthony Li on 10/19/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import Foundation

enum APIResultSource {
    case cached
    case fetched
}

struct APIResult<R> {
    let ok: Bool
    let error: Error!
    let result: R!
    let source: APIResultSource
}

enum APICachingMode {
    case forceFetch
    case forceCache
    case preferCache
    case both
}

enum APIError: Error {
    case noData
}

class APIService {
    static var shared = APIService(url: URL(string: "https://db.yourbcabus.com")!, cacheURL: URL(fileURLWithPath:  NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!))
    
    init(url: URL, cacheURL: URL) {
        self.url = url
        self.cacheURL = cacheURL
        encoder.outputFormatting = .prettyPrinted
    }
    
    let url: URL
    let cacheURL: URL
    let urlSession = URLSession(configuration: .default)
    
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private func getURLForCache(identifier: String) -> URL {
        return cacheURL.appendingPathComponent(identifier).appendingPathExtension("json")
    }
    
    func readCache<T>(identifier: String) throws -> T where T: Decodable {
        let data = try Data(contentsOf: getURLForCache(identifier: identifier))
        return try decoder.decode(T.self, from: data)
    }
    
    func writeCache<T>(_ object: T, identifier: String) where T: Encodable {
        if let data = try? encoder.encode(object) {
            try? data.write(to: getURLForCache(identifier: identifier))
        }
    }
    
    func fetchFromAPI(path: String, _ completion: @escaping (Data?, Error?) -> Void) {
        let resourceURL = (path as NSString).pathComponents.reduce(url) { (url, component) in
            return url.appendingPathComponent(component)
        }
        
        let task = urlSession.dataTask(with: resourceURL) { (data, response, e) in
            guard e == nil else {
                completion(nil, e!)
                return
            }
            
            guard let d = data else {
                completion(nil, APIError.noData)
                return
            }
            
            completion(d, nil)
        }
        
        task.resume()
    }
    
    private func getResource<T>(apiPath: String, cachedAs cacheIdentifier: String, cachingMode: APICachingMode, _ completion: @escaping (APIResult<T>) -> Void) where T: Codable {
        
        if cachingMode != .forceFetch {
            do {
                completion(APIResult(ok: true, error: nil, result: try readCache(identifier: cacheIdentifier), source: .cached))
                
                if cachingMode == .preferCache {
                    return
                }
            } catch {
                if cachingMode == .forceCache {
                    completion(APIResult(ok: false, error: error, result: nil, source: .cached))
                }
            }
        }
        
        if cachingMode != .forceCache {
            fetchFromAPI(path: apiPath) { (data, error) in
                guard error == nil else {
                    completion(APIResult(ok: false, error: error!, result: nil, source: .fetched))
                    return
                }
                
                do {
                    let object = try self.decoder.decode(T.self, from: data!)
                    completion(APIResult(ok: true, error: nil, result: object, source: .fetched))
                    self.writeCache(object, identifier: cacheIdentifier)
                } catch {
                    completion(APIResult(ok: false, error: error, result: nil, source: .fetched))
                }
            }
        }
    }
    
    func getBuses(schoolId: String, cachingMode: APICachingMode = .both, _ completion: @escaping (APIResult<[Bus]>) -> Void) {
        getResource(apiPath: "/schools/\(schoolId)/buses", cachedAs: "\(schoolId).buses", cachingMode: cachingMode, completion)
    }
}
