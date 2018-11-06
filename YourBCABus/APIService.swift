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
    case noCacheIdentifier
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
    
    func fetchFromAPI(path: String, query: [URLQueryItem]?, _ completion: @escaping (Data?, Error?) -> Void) {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        components.path = path
        components.queryItems = query
        
        let task = urlSession.dataTask(with: components.url!) { (data, response, e) in
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
    
    private func getResource<T>(apiPath: String, query: [URLQueryItem]? = nil, cachedAs cacheIdentifier: String?, cachingMode: APICachingMode, _ completion: @escaping (APIResult<T>) -> Void) where T: Codable {
        var didFetchFromCache = false
        
        if cachingMode != .forceFetch {
            do {
                if let identifier = cacheIdentifier {
                    completion(APIResult(ok: true, error: nil, result: try readCache(identifier: identifier), source: .cached))
                    didFetchFromCache = true
                } else {
                    throw APIError.noCacheIdentifier
                }
                
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
            fetchFromAPI(path: apiPath, query: query) { (data, error) in
                guard error == nil else {
                    if (!didFetchFromCache) {
                        completion(APIResult(ok: false, error: error!, result: nil, source: .fetched))
                    }
                    return
                }
                
                do {
                    let object = try self.decoder.decode(T.self, from: data!)
                    completion(APIResult(ok: true, error: nil, result: object, source: .fetched))
                    if let identifier = cacheIdentifier {
                        self.writeCache(object, identifier: identifier)
                    }
                } catch {
                    if !didFetchFromCache {
                        completion(APIResult(ok: false, error: error, result: nil, source: .fetched))
                    }
                }
            }
        }
    }
    
    func getSchool(schoolId: String, cachingMode: APICachingMode = .preferCache, _ completion: @escaping (APIResult<School>) -> Void) {
        getResource(apiPath: "/schools/\(schoolId)", cachedAs: "\(schoolId)", cachingMode: cachingMode, completion)
    }
    
    func getBuses(schoolId: String, cachingMode: APICachingMode = .preferCache, _ completion: @escaping (APIResult<[Bus]>) -> Void) {
        getResource(apiPath: "/schools/\(schoolId)/buses", cachedAs: "\(schoolId).buses", cachingMode: cachingMode, completion)
    }
    
    func getBus(schoolId: String, busId: String, _ completion: @escaping (APIResult<[Bus]>) -> Void) {
        getResource(apiPath: "/schools/\(schoolId)/buses/\(busId)", cachedAs: nil, cachingMode: .forceFetch, completion)
    }
    
    func getStops(schoolId: String, busId: String, cachingMode: APICachingMode = .preferCache, _ completion: @escaping (APIResult<[Stop]>) -> Void) {
        getResource(apiPath: "/schools/\(schoolId)/buses/\(busId)/stops", cachedAs: "\(schoolId).buses.\(busId).stops", cachingMode: cachingMode, completion)
    }
    
    func getStops(schoolId: String, near coord: Coordinate, distance: Int?, _ completion: @escaping (APIResult<[Stop]>) -> Void) {
        var query = [URLQueryItem(name: "latitude", value: String(coord.latitude)), URLQueryItem(name: "longitude", value: String(coord.longitude))]
        if let dist = distance {
            query.append(URLQueryItem(name: "distance", value: String(dist)))
        }
        
        getResource(apiPath: "/schools/\(schoolId)/stops/nearby", query: query, cachedAs: nil, cachingMode: .forceFetch, completion)
    }
}
