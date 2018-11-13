//
//  Routes.swift
//  YourBCABus
//
//  Created by Anthony Li on 11/7/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import Foundation
import MapKit

class Route: CustomStringConvertible {
    enum Step {
        case boarding
        case riding
        case walking
        case andItsFamilyAfterGenus
    }
    
    enum FetchStatus {
        case notFetched
        case fetching
        case errored
        case fetched
    }
    
    enum RouteError: Error {
        case busNotFound
    }
    
    var steps = [Step]()
    var eta: Date?
    
    let destination: MKMapItem
    let stop: Stop?
    let schoolId: String
    var bus: Bus?
    var stops: [Stop]?
    var school: School?
    var walkingRoute: MKRoute?
    
    var fetchStatus: FetchStatus {
        return _fetchStatus
    }
    
    private var _fetchStatus = FetchStatus.notFetched
    
    init(destination: MKMapItem, stop: Stop?, schoolId: String) {
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
    
    func fetchData(_ update: @escaping (Bool, Error?, Route) -> Void) {
        _fetchStatus = .fetching
        if let stop = stop {
            APIService.shared.getBuses(schoolId: schoolId, cachingMode: .preferCache) { result in
                if result.ok {
                    if let bus = result.result.first(where: { bus in
                        return bus._id == stop.bus_id
                    }) {
                        self.bus = bus
                        update(true, nil, self)
                        
                        APIService.shared.getStops(schoolId: self.schoolId, busId: bus._id, cachingMode: .preferCache) { result in
                            if result.ok {
                                
                            }
                            
                            if let arrives = stop.arrives {
                                DirectionsCache.shared.getDirections(origin: MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(from: stop.location))), destination: self.destination, departure: arrives) { (resp, error) in
                                    if let response = resp {
                                        self.walkingRoute = response.routes.first!
                                        self.eta = arrives.addingTimeInterval(self.walkingRoute!.expectedTravelTime)
                                        self._fetchStatus = .fetched
                                        update(true, nil, self)
                                    } else {
                                        self._fetchStatus = .errored
                                        update(false, error!, self)
                                    }
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
                            self.eta = departureTime.addingTimeInterval(self.walkingRoute!.expectedTravelTime)
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
    
    var description: String {
        if let name = stop?.name {
            return name
        } else {
            return "Walking"
        }
    }
}

class DirectionsCache {
    static var shared = DirectionsCache()
    
    var cache = [CoordinatePair: MKDirections.Response]()
    
    func getDirections(origin: MKMapItem, destination: MKMapItem, departure: Date, _ handler: @escaping MKDirections.DirectionsHandler) {
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
}
