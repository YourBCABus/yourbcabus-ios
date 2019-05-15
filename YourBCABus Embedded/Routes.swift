//
//  Routes.swift
//  YourBCABus
//
//  Created by Anthony Li on 11/7/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import Foundation
import MapKit

public class Route: CustomStringConvertible, Codable {
    enum CodingKeys: String, CodingKey {
        case mapKitData = "mapKitData"
        case walkingPolyline
        case walkingETA
        case walkingDistance
        case stop
        case eta
        case steps
        case bus
        case stops
        case school
        case schoolId
        case fetchStatus
    }
    
    public enum Step: Int, Codable {
        case boarding
        case riding
        case walking
        case andItsFamilyAfterGenus
    }
    
    public enum FetchStatus: Int, Codable {
        case notFetched
        case fetching
        case errored
        case fetched
    }
    
    public enum RouteError: Error {
        case busNotFound
    }
    
    public var steps = [Step]()
    public var eta: Date?
    
    public let destination: MKMapItem
    public var stop: Stop?
    public let schoolId: String
    public var bus: Bus?
    public var stops: [Stop]?
    public var school: School?
    
    public var walkingPolyline: MKPolyline?
    public var walkingETA: TimeInterval?
    public var walkingDistance: CLLocationDistance?
    
    private var walkingRoute: MKRoute? {
        get {
            return nil
        }
        set {
            walkingPolyline = newValue!.polyline
            walkingETA = newValue!.expectedTravelTime
            walkingDistance = newValue!.distance
        }
    }
    
    public var fetchStatus: FetchStatus {
        return _fetchStatus
    }
    
    private var _fetchStatus = FetchStatus.notFetched
    
    private struct Point: Codable {
        let x: Double
        let y: Double
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(NSKeyedArchiver.archivedData(withRootObject: destination, requiringSecureCoding: true), forKey: .mapKitData)
        
        try container.encode(stop, forKey: .stop)
        try container.encode(steps, forKey: .steps)
        try container.encode(eta, forKey: .eta)
        try container.encode(schoolId, forKey: .schoolId)
        try container.encode(bus, forKey: .bus)
        try container.encode(stops, forKey: .stops)
        try container.encode(school, forKey: .school)
        try container.encode(fetchStatus, forKey: .fetchStatus)
        
        if let polyline = walkingPolyline {
            let points = [MKMapPoint](UnsafeBufferPointer<MKMapPoint>(start: polyline.points(), count: polyline.pointCount))
            
            try container.encode(points.map {Point(x: $0.x, y: $0.y)}, forKey: .walkingPolyline)
            try container.encode(walkingETA!, forKey: .walkingETA)
            try container.encode(walkingDistance!, forKey: .walkingDistance)
        }
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        steps = try container.decode([Step].self, forKey: .steps)
        if container.contains(.eta) {
            eta = try container.decode(Date.self, forKey: .eta)
        } else {
            eta = nil
        }
        if container.contains(.stop) {
            stop = try container.decode(Stop?.self, forKey: .stop)
        } else {
            stop = nil
        }
        if container.contains(.bus) {
            bus = try container.decode(Bus?.self, forKey: .bus)
        } else {
            bus = nil
        }
        if container.contains(.stops) {
            stops = try container.decode([Stop]?.self, forKey: .stops)
        } else {
            stops = nil
        }
        if container.contains(.school) {
            school = try container.decode(School?.self, forKey: .school)
        } else {
            school = nil
        }
        schoolId = try container.decode(String.self, forKey: .schoolId)
        _fetchStatus = try container.decode(FetchStatus.self, forKey: .fetchStatus)
        
        let data = try container.decode(Data.self, forKey: .mapKitData)
        destination = try NSKeyedUnarchiver.unarchivedObject(ofClass: MKMapItem.self, from: data)!
        
        if container.contains(.walkingPolyline) {
            let points = try container.decode([Point].self, forKey: .walkingPolyline)
            let mapPoints = points.map({MKMapPoint(x: $0.x, y: $0.y).coordinate})
            walkingPolyline = MKPolyline(coordinates: mapPoints, count: mapPoints.count)
            
            walkingETA = try container.decode(TimeInterval.self, forKey: .walkingETA)
            walkingDistance = try container.decode(CLLocationDistance.self, forKey: .walkingDistance)
        }
    }
    
    public init(destination: MKMapItem, stop: Stop?, schoolId: String) {
        self.destination = destination
        self.stop = stop
        self.schoolId = schoolId
        if let theStop = stop {
            if destination.placemark.location != nil && CLLocation(latitude: theStop.location.latitude, longitude: theStop.location.longitude).distance(from: destination.placemark.location!) <= 20 {
                steps = [.boarding, .riding]
            } else {
                steps = [.boarding, .riding, .walking]
            }
        } else {
            steps = [.walking]
        }
    }
    
    public func fetchData(_ update: @escaping (Bool, Error?, Route) -> Void) {
        _fetchStatus = .fetching
        if var stop = stop {
            APIService.shared.getBuses(schoolId: schoolId, cachingMode: .preferCache) { result in
                if result.ok {
                    if let bus = result.result.first(where: { bus in
                        return bus._id == stop.bus_id
                    }) {
                        self.bus = bus
                        update(true, nil, self)
                        
                        APIService.shared.getStops(schoolId: self.schoolId, busId: bus._id, cachingMode: .forceFetch) { result in
                            if result.ok {
                                let stops = result.result.sorted()
                                if let index = stops.firstIndex(where: {$0._id == stop._id}) {
                                    self.stops = Array(stops[0..<index])
                                    stop.arrives = stops[index].arrives
                                } else {
                                    let coordinate = CLLocationCoordinate2D(from: stop.location)
                                    if let index = stops.firstIndex(where: { stop in
                                        let stopCoordinate = CLLocationCoordinate2D(from: stop.location)
                                        return CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude).distance(from: CLLocation(latitude: stopCoordinate.latitude, longitude: stopCoordinate.longitude)) < 150
                                    }) {
                                        self.stops = Array(stops[0..<index])
                                        if stop.is_custom {
                                            if let date = stops[index].arrives {
                                                stop.arrives = date
                                                self.stop!.arrives = date
                                            }
                                        }
                                    }
                                }
                            }
                            
                            if let arrives = stop.arrives {
                                DirectionsCache.shared.getDirections(origin: MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(from: stop.location))), destination: self.destination, departure: arrives) { (resp, error) in
                                    if let response = resp {
                                        let walkingRoute = response.routes.first!
                                        self.walkingRoute = walkingRoute
                                        self.eta = arrives.addingTimeInterval(walkingRoute.expectedTravelTime)
                                        
                                        APIService.shared.getSchool(schoolId: self.schoolId, cachingMode: .preferCache) { result in
                                            if result.ok {
                                                self.school = result.result
                                            }
                                            
                                            self._fetchStatus = .fetched
                                            update(true, nil, self)
                                        }
                                    } else {
                                        self._fetchStatus = .errored
                                        update(false, error!, self)
                                    }
                                }
                            } else {
                                APIService.shared.getSchool(schoolId: self.schoolId, cachingMode: .preferCache) { result in
                                    if result.ok {
                                        self.school = result.result
                                    }
                                    
                                    self._fetchStatus = .fetched
                                    update(true, nil, self)
                                }
                            }
                        }
                    } else {
                        self._fetchStatus = .errored
                        update(false, RouteError.busNotFound, self)
                    }
                } else {
                    self._fetchStatus = .errored
                    update(false, result.error, self)
                }
            }
        } else {
            APIService.shared.getSchool(schoolId: schoolId) { result in
                if result.ok {
                    self.school = result.result
                    
                    let date = Date()
                    var components = DateComponents()
                    components.calendar = Calendar(identifier: .gregorian)
                    components.timeZone = TimeZone(abbreviation: "America/New_York")
                    components.year = 2018
                    components.month = 1
                    components.day = 1
                    components.hour = 16
                    components.minute = 10
                    components.second = 0
                    components.nanosecond = 0
                    
                    let departureTime = Date(timeIntervalSince1970: floor(date.timeIntervalSince1970 / 86400) * 86400 + TimeInterval(Int(components.date!.timeIntervalSince1970) % 86400))
                    
                    let request = MKDirections.Request()
                    request.transportType = .walking
                    request.departureDate = departureTime
                    request.source = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(from: self.school!.location)))
                    request.destination = self.destination
                    
                    DirectionsCache.shared.getDirections(origin: MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(from: self.school!.location))), destination: self.destination, departure: departureTime) { (resp, error) in
                        if let response = resp {
                            self.walkingRoute = response.routes.first!
                            self.eta = departureTime.addingTimeInterval(response.routes.first!.expectedTravelTime)
                            self._fetchStatus = .fetched
                            update(true, nil, self)
                        } else {
                            self._fetchStatus = .errored
                            update(false, error!, self)
                        }
                    }
                } else {
                    self._fetchStatus = .errored
                    update(false, result.error, self)
                }
            }
        }
    }
    
    public var description: String {
        if let name = stop?.name {
            return name
        } else {
            return "Walking"
        }
    }
}

public class DirectionsCache {
    public static var shared = DirectionsCache()
    
    var cache = [CoordinatePair: MKDirections.Response]()
    
    public func getDirections(origin: MKMapItem, destination: MKMapItem, departure: Date, _ handler: @escaping MKDirections.DirectionsHandler) {
        let key = CoordinatePair(origin: Coordinate(from: origin.placemark.coordinate), destination: Coordinate(from: destination.placemark.coordinate))
        if let cached = cache[key] {
            handler(cached, nil)
        } else {
            let request = MKDirections.Request()
            request.transportType = .walking
            request.departureDate = departure
            request.source = origin
            request.destination = destination
            
            let directions = MKDirections(request: request)
            directions.calculate(completionHandler: { [weak self] (resp, err) in
                if let response = resp {
                    self?.cache[key] = response
                }
                
                handler(resp, err)
            })
        }
    }

    public func clearCache() {
        cache = [:]
    }
}

public extension MKMapRect {
    public init(a: MKMapPoint, b: MKMapPoint) {
        self.init(x: min(a.x, b.x), y: min(a.y, b.y), width: abs(a.x - b.x), height: abs(a.y - b.y))
    }
}
