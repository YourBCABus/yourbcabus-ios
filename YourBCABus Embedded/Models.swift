//
//  Models.swift
//  YourBCABus
//
//  Created by Anthony Li on 10/19/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import Foundation
import CoreLocation

public struct Coordinate: Codable, Equatable, Hashable {
    public let latitude: Double
    public let longitude: Double
    
    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    public init(from coordinate: CLLocationCoordinate2D) {
        self.init(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
    
    public static func == (a: Coordinate, b: Coordinate) -> Bool {
        return a.latitude == b.latitude && a.longitude == b.longitude
    }
    
    public func hash(into hasher: inout Hasher) {
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

public struct School: Codable {
    public let _id: String
    public let name: String
    public let location: Coordinate
    public let timezone: String?
}

public struct Bus: Codable, Comparable, CustomStringConvertible {
    static private let formatter = ISO8601DateFormatter()
    static private func formatDate(from: String) -> Date? {
        var temp = from
        if let match = temp.firstIndex(of: ".") {
            temp.removeSubrange(match...temp.index(match, offsetBy: 3))
        }
        return Bus.formatter.date(from: temp)
    }
    
    public static let locationKey = "location"
    
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
    
    public init(from decoder: Decoder) throws {
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
    
    public let _id: String
    public let school_id: String
    public let available: Bool
    public let name: String?
    public let locations: [String]
    public let boarding: Int?
    public let departing: Int?
    
    var invalidate_time: String? {
        get {
            guard let date = invalidates else {
                return nil
            }
            
            return Bus.formatter.string(from: date)
        }
    }
    public let invalidates: Date?
    
    public func isValidated(asOf date: Date = Date()) -> Bool {
        guard let invalidate = invalidates else {
            return true
        }
        
        return date < invalidate
    }
    public var validated: Bool { return isValidated() }
    
    public var description: String {
        return name == nil ? "" : name!
    }
    
    public var location: String? {
        return isValidated() ? locations.first : nil
    }
    
    public static func == (a: Bus, b: Bus) -> Bool {
        return (a.available == b.available) && (a.name == b.name)
    }
    
    public static func > (a: Bus, b: Bus) -> Bool {
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
    
    public static func < (a: Bus, b: Bus) -> Bool {
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

public struct Stop: Codable, Comparable, CustomStringConvertible {
    static private let formatter = ISO8601DateFormatter()
    static private func formatDate(from: String) -> Date? {
        var temp = from
        if let match = temp.firstIndex(of: ".") {
            temp.removeSubrange(match...temp.index(match, offsetBy: 3))
        }
        return Stop.formatter.date(from: temp)
    }
    
    public static func getArrivalTimeForCustomStop(date: Date, now: Date = Date()) -> Date? {
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
    
    public static let customStopIdPrefix = "YBBCustomStopIOS"
    
    public init(from decoder: Decoder) throws {
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
    
    public init(customStopAt location: Coordinate, bus bus_id: String, arrivesAt arrives: Date? = nil, name: String? = nil, order: Double = 0, id _id: String = "\(Stop.customStopIdPrefix).\(UUID().uuidString)") {
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
    
    public let _id: String
    public let bus_id: String
    public let name: String?
    public let location: Coordinate
    public let order: Double
    public var arrives: Date?
    public let invalidates: Date?
    public let available: Bool
    public let is_custom: Bool
    
    public static func < (a: Stop, b: Stop) -> Bool {
        return a.order < b.order
    }
    
    public static func == (a: Stop, b: Stop) -> Bool {
        return a.order == b.order
    }
    
    public static func > (a: Stop, b: Stop) -> Bool {
        return a.order > b.order
    }
    
    public var description: String {
        if let name = name {
            return name
        } else {
            return "\(location.latitude), \(location.longitude)"
        }
    }
}

public enum BusStatus: CustomStringConvertible {
    case unavailable
    case notArrived(boarding: Int?)
    case arrived
    
    public var description: String {
        switch self {
        case .unavailable:
            return "Not running"
        case .notArrived(let boarding):
            if let time = boarding {
                let group: String
                
                if time < 150 {
                    group = "Early"
                } else if time <= 600 {
                    group = "On Time"
                } else if time <= 900 {
                    group = "Slightly Late"
                } else if time < 1200 {
                    group = "Late"
                } else {
                    group = "Very Late"
                }
                
                return "Expected \(group)"
            } else {
                return "Not at BCA"
            }
        case .arrived:
            return "Arrived at BCA"
        default:
            return "Unknown"
        }
    }
}

public extension Bus {
    public var status: BusStatus {
        guard available else {
            return .unavailable
        }
        
        if location == nil {
            return .notArrived(boarding: validated ? boarding : nil)
        } else {
            return .arrived
        }
    }
    
    @available(*, deprecated, message: "Use status instead") func getStatus() -> String {
        return status.description
    }
}

public extension CLLocationCoordinate2D {
    public init(from: Coordinate) {
        self.init(latitude: CLLocationDegrees(from.latitude), longitude: CLLocationDegrees(from.longitude))
    }
}

public struct DismissalResult: Codable {
    public let ok: Bool
    public let found: Bool?
    public let dismissal_time: Int?
    public let departure_time: Int?
    public let start_time: Int?
    public let end_time: Int?
}
