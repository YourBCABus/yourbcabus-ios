//
//  APIService.swift
//  YourBCABus
//
//  Created by Anthony Li on 10/19/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import Foundation

public enum APIResultSource {
    case cached
    case fetched
}

public struct APIResult<R> {
    public let ok: Bool
    public let error: Error!
    public let result: R!
    public let source: APIResultSource
}

public enum APICachingMode {
    case forceFetch
    case forceCache
    case preferCache
    case both
}

public enum APIError: Error {
    case noData
    case noCacheIdentifier
    case noAuthToken
}

public class APIService {
    public static var shared = APIService(url: URL(string: "https://db.yourbcabus.com")!, cacheURL: URL(fileURLWithPath:  NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true).first!), authToken: "NjSnf2C/ewoFUaLe5ibvVKMatTP51o1GW5zZB7+BJxY=")
    
    public init(url: URL, cacheURL: URL, authToken: String? = nil) {
        self.url = url
        self.cacheURL = cacheURL
        self.authToken = authToken
        encoder.outputFormatting = .prettyPrinted
    }
    
    let url: URL
    let authToken: String?
    let cacheURL: URL
    let urlSession = URLSession(configuration: .default)
    
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private func getURLForCache(identifier: String) -> URL {
        return cacheURL.appendingPathComponent(identifier).appendingPathExtension("json")
    }
    
    private func readCache<T>(identifier: String) throws -> T where T: Decodable {
        let data = try Data(contentsOf: getURLForCache(identifier: identifier))
        return try decoder.decode(T.self, from: data)
    }
    
    private func writeCache<T>(_ object: T, identifier: String) where T: Encodable {
        if let data = try? encoder.encode(object) {
            try? data.write(to: getURLForCache(identifier: identifier))
        }
    }
    
    private func fetchFromAPI(path: String, query: [URLQueryItem]?, _ completion: @escaping (Data?, Error?) -> Void) {
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
    
    public func getSchool(schoolId: String, cachingMode: APICachingMode = .preferCache, _ completion: @escaping (APIResult<School>) -> Void) {
        getResource(apiPath: "/schools/\(schoolId)", cachedAs: "\(schoolId)", cachingMode: cachingMode, completion)
    }
    
    public func getBuses(schoolId: String, cachingMode: APICachingMode = .preferCache, _ completion: @escaping (APIResult<[Bus]>) -> Void) {
        getResource(apiPath: "/schools/\(schoolId)/buses", cachedAs: "\(schoolId).buses", cachingMode: cachingMode, completion)
    }
    
    public func getBus(schoolId: String, busId: String, _ completion: @escaping (APIResult<Bus>) -> Void) {
        getResource(apiPath: "/schools/\(schoolId)/buses/\(busId)", cachedAs: nil, cachingMode: .forceFetch, completion)
    }
    
    public func getStops(schoolId: String, busId: String, cachingMode: APICachingMode = .preferCache, _ completion: @escaping (APIResult<[Stop]>) -> Void) {
        getResource(apiPath: "/schools/\(schoolId)/buses/\(busId)/stops", cachedAs: "\(schoolId).buses.\(busId).stops", cachingMode: cachingMode, completion)
    }
    
    public func getStops(schoolId: String, near coord: Coordinate, distance: Int?, _ completion: @escaping (APIResult<[Stop]>) -> Void) {
        var query = [URLQueryItem(name: "latitude", value: String(coord.latitude)), URLQueryItem(name: "longitude", value: String(coord.longitude))]
        if let dist = distance {
            query.append(URLQueryItem(name: "distance", value: String(dist)))
        }
        
        getResource(apiPath: "/schools/\(schoolId)/stops/nearby", query: query, cachedAs: nil, cachingMode: .forceFetch, completion)
    }
    
    public func getAlerts(schoolId: String, cachingMode: APICachingMode = .forceFetch, _ completion: @escaping (APIResult<[Alert]>) -> Void) {
        getResource(apiPath: "/schools/\(schoolId)/alerts", cachedAs: "\(schoolId).alerts", cachingMode: .forceFetch, completion)
    }
    
    public func getDismissal(schoolId: String, date: Date = Date(), cachingMode: APICachingMode = .preferCache, _ completion: @escaping (APIResult<DismissalResult>) -> Void) {
        let time = Int(date.timeIntervalSince1970)
        getResource(apiPath: "/schools/\(schoolId)/dismissal", query: [URLQueryItem(name: "date", value: String(time))], cachedAs: "\(schoolId).dismissal.\(time)", cachingMode: cachingMode, completion)
    }
    
    private func postResource<Resource: Encodable>(_ data: Resource, toPath path: String, query: [URLQueryItem]? = nil, withAuthToken useAuthToken: Bool = false, _ completion: ((APIResult<Void>) -> Void)?) throws {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        components.path = path
        components.queryItems = query
        
        let encoder = JSONEncoder()
        let json = try encoder.encode(data)
        
        var request = URLRequest(url: components.url!)
        if useAuthToken {
            guard let token = authToken else { throw APIError.noAuthToken }
            request.setValue("Basic \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let task = urlSession.uploadTask(with: request, from: json) { (data, response, e) in
            guard e == nil else {
                completion?(APIResult(ok: false, error: e, result: nil, source: .fetched))
                return
            }
            
            completion?(APIResult(ok: true, error: nil, result: (), source: .fetched))
        }
        
        task.resume()
    }
    
    private struct StopSuggestionData: Encodable {
        let location: Coordinate
        let time: Int?
    }
    
    public func suggestStop(schoolId: String, stop: Stop, _ completion: ((APIResult<Void>) -> Void)?) throws {
        let data = StopSuggestionData(location: stop.location, time: stop.arrives == nil ? nil : Int(stop.arrives!.timeIntervalSince1970 * 1000))
        
        try postResource(data, toPath: "/schools/\(schoolId)/buses/\(stop.bus_id)/stopsuggest", withAuthToken: true, completion)
    }
}
