//
//  Models.swift
//  YourBCABus
//
//  Created by Anthony Li on 10/19/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import Foundation
import CoreLocation

struct Coordinate: Codable, Equatable, Hashable {
    let latitude: Double
    let longitude: Double
    
    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    init(from coordinate: CLLocationCoordinate2D) {
        self.init(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
    
    static func == (a: Coordinate, b: Coordinate) -> Bool {
        return a.latitude == b.latitude && a.longitude == b.longitude
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }
}

struct CoordinatePair: Equatable, Hashable {
    let origin: Coordinate
    let destination: Coordinate
    
    static func == (a: CoordinatePair, b: CoordinatePair) -> Bool {
        return a.origin == b.origin && a.destination == b.destination
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(origin)
        hasher.combine(destination)
    }
}

struct School: Codable {
    let _id: String
    let name: String
    let location: Coordinate
}

struct Bus: Codable, Comparable, CustomStringConvertible {
    static private let formatter = ISO8601DateFormatter()
    static private func formatDate(from: String) -> Date? {
        var temp = from
        if let match = temp.firstIndex(of: ".") {
            temp.removeSubrange(match...temp.index(match, offsetBy: 3))
        }
        return Bus.formatter.date(from: temp)
    }
    
    static let locationKey = "location"
    
    enum BusKeys: String, CodingKey {
        case _id = "_id"
        case school_id = "school_id"
        case available = "available"
        case name = "name"
        case locations = "locations"
        case boarding = "boarding"
        case departing = "departing"
        case invalidate_time = "invalidate_time"
        case invalidates = "invalidates"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: BusKeys.self)
        _id = try container.decode(String.self, forKey: ._id)
        school_id = try container.decode(String.self, forKey: .school_id)
        available = try container.decode(Bool.self, forKey: .available)
        name = container.contains(.name) ? try container.decode(String.self, forKey: .name) : nil
        locations = try container.decode([String].self, forKey: .locations)
        boarding = container.contains(.boarding) ? try container.decode(Int.self, forKey: .boarding) : nil
        departing = container.contains(.departing) ? try container.decode(Int.self, forKey: .departing) : nil
        
        if container.contains(.invalidates) {
            invalidates = try container.decode(Date.self, forKey: .invalidates)
        } else {
            let invalidate_time = container.contains(.invalidate_time) ? try container.decode(String?.self, forKey: .invalidate_time) : nil
            if let time = invalidate_time {
                invalidates = Bus.formatDate(from: time)
            } else {
                invalidates = nil
            }
        }
    }
    
    let _id: String
    let school_id: String
    let available: Bool
    let name: String?
    let locations: [String]
    let boarding: Int?
    let departing: Int?
    
    var invalidate_time: String? {
        get {
            guard let date = invalidates else {
                return nil
            }
            
            return Bus.formatter.string(from: date)
        }
    }
    let invalidates: Date?
    
    func isValidated(asOf date: Date = Date()) -> Bool {
        guard let invalidate = invalidates else {
            return true
        }
        
        return date < invalidate
    }
    var validated: Bool { return isValidated() }
    
    var description: String {
        return name == nil ? "" : name!
    }
    
    var location: String? {
        return isValidated() ? locations.first : nil
    }
    
    static func == (a: Bus, b: Bus) -> Bool {
        return (a.available == b.available) && (a.name == b.name)
    }
    
    static func > (a: Bus, b: Bus) -> Bool {
        if a.available && !b.available {
            return false
        } else if !a.available && b.available {
            return true
        } else {
            if a.name == nil {
                return false
            } else if b.name == nil {
                return true
            } else {
                return a.name! > b.name!
            }
        }
    }
    
    static func < (a: Bus, b: Bus) -> Bool {
        if a.available && !b.available {
            return true
        } else if !a.available && b.available {
            return false
        } else {
            if a.name == nil {
                return true
            } else if b.name == nil {
                return false
            } else {
                return a.name! < b.name!
            }
        }
    }
}

struct Stop: Codable, Comparable, CustomStringConvertible {
    static private let formatter = ISO8601DateFormatter()
    static private func formatDate(from: String) -> Date? {
        var temp = from
        if let match = temp.firstIndex(of: ".") {
            temp.removeSubrange(match...temp.index(match, offsetBy: 3))
        }
        return Stop.formatter.date(from: temp)
    }
    
    static func getArrivalTimeForCustomStop(date: Date, now: Date = Date()) -> Date? {
        let calendar = Calendar(identifier: .gregorian)
        var components = calendar.dateComponents([.calendar, .timeZone, .era, .year, .month, .day], from: now)
        components.hour = calendar.component(.hour, from: date)
        components.minute = calendar.component(.minute, from: date)
        components.second = calendar.component(.second, from: date)
        components.nanosecond = calendar.component(.nanosecond, from: date)
        return calendar.date(from: components)
    }
    
    enum Keys: String, CodingKey {
        case _id = "_id"
        case bus_id = "bus_id"
        case available = "available"
        case name = "name"
        case location = "location"
        case arrival_time = "arrival_time"
        case invalidate_time = "invalidate_time"
        case arrives = "arrives"
        case invalidates = "invalidates"
        case order = "order"
        case is_custom = "is_custom"
    }
    
    static let customStopIdPrefix = "YBBCustomStopIOS"
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        _id = try container.decode(String.self, forKey: ._id)
        bus_id = try container.decode(String.self, forKey: .bus_id)
        available = try container.decode(Bool.self, forKey: .available)
        name = container.contains(.name) ? try container.decode(String.self, forKey: .name) : nil
        location = try container.decode(Coordinate.self, forKey: .location)
        order = try container.decode(Double.self, forKey: .order)
        is_custom = try (container.contains(.is_custom) && container.decode(Bool.self, forKey: .is_custom))
        
        if container.contains(.arrives) {
            let date = try container.decode(Date.self, forKey: .arrives)
            arrives = is_custom ? Stop.getArrivalTimeForCustomStop(date: date) : date
        } else {
            let arrival_time = container.contains(.arrival_time) ? try container.decode(String?.self, forKey: .arrival_time) : nil
            if let time = arrival_time {
                arrives = Stop.formatDate(from: time)
            } else {
                arrives = nil
            }
        }
        
        if container.contains(.invalidates) {
            invalidates = try container.decode(Date.self, forKey: .invalidates)
        } else {
            let invalidate_time = container.contains(.invalidate_time) ? try container.decode(String?.self, forKey: .invalidate_time) : nil
            if let time = invalidate_time {
                invalidates = Stop.formatDate(from: time)
            } else {
                invalidates = nil
            }
        }
    }
    
    init(customStopAt location: Coordinate, bus bus_id: String, arrivesAt arrives: Date? = nil, name: String? = nil, order: Double = 0, id _id: String = "\(Stop.customStopIdPrefix).\(UUID().uuidString)") {
        self._id = _id
        self.bus_id = bus_id
        self.name = name
        self.location = location
        self.order = order
        self.invalidates = nil
        self.available = true
        self.is_custom = true
        
        if let date = arrives {
            self.arrives = Stop.getArrivalTimeForCustomStop(date: date)
        } else {
            self.arrives = nil
        }
    }
    
    let _id: String
    let bus_id: String
    let name: String?
    let location: Coordinate
    let order: Double
    var arrives: Date?
    let invalidates: Date?
    let available: Bool
    let is_custom: Bool
    
    static func < (a: Stop, b: Stop) -> Bool {
        return a.order < b.order
    }
    
    static func == (a: Stop, b: Stop) -> Bool {
        return a.order == b.order
    }
    
    static func > (a: Stop, b: Stop) -> Bool {
        return a.order > b.order
    }
    
    var description: String {
        if let name = name {
            return name
        } else {
            return "\(location.latitude), \(location.longitude)"
        }
    }
}

extension Bus {
    var status: String {
        guard self.available else {
            return "Not running"
        }
        
        if self.location == nil {
            if validated {
                if let boarding = self.boarding {
                    let group: String
                    
                    if boarding <= 150 {
                        group = "Early"
                    } else if boarding <= 600 {
                        group = "On Time"
                    } else if boarding <= 900 {
                        group = "Slightly Late"
                    } else if boarding < 1200 {
                        group = "Late"
                    } else {
                        group = "Very Late"
                    }
                    
                    return "Expected \(group) (\(boarding))"
                }
            }
            
            return "Not at BCA"
        }
        
        return "Arrived at BCA"
    }
    
    @available(*, deprecated, message: "Use status instead") func getStatus() -> String {
        return status
    }
}

extension CLLocationCoordinate2D {
    init(from: Coordinate) {
        self.init(latitude: CLLocationDegrees(from.latitude), longitude: CLLocationDegrees(from.longitude))
    }
}
