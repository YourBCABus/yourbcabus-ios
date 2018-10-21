//
//  Models.swift
//  YourBCABus
//
//  Created by Anthony Li on 10/19/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import Foundation

struct Bus: Codable, Comparable, CustomStringConvertible {
    static private let formatter = ISO8601DateFormatter()
    
    let _id: String
    let school_id: String
    let available: Bool
    let name: String?
    let locations: [String]?
    var boarding_time: String? {
        get {
            guard let date = boards else {
                return nil
            }
            
            return Bus.formatter.string(from: date)
        }
        set {
            guard let string = newValue else {
                boards = nil
                return
            }
            
            boards = Bus.formatter.date(from: string)
        }
    }
    var departure_time: String? {
        get {
            guard let date = departs else {
                return nil
            }
            
            return Bus.formatter.string(from: date)
        }
        set {
            guard let string = newValue else {
                departs = nil
                return
            }
            
            departs = Bus.formatter.date(from: string)
        }
    }
    var invalidate_time: String? {
        get {
            guard let date = invalidates else {
                return nil
            }
            
            return Bus.formatter.string(from: date)
        }
        set {
            guard let string = newValue else {
                invalidates = nil
                return
            }
            
            invalidates = Bus.formatter.date(from: string)
        }
    }
    
    var boards: Date?
    var departs: Date?
    var invalidates: Date?
    
    func isValidated(asOf date: Date = Date()) -> Bool {
        guard let invalidate = invalidates else {
            return false
        }
        
        return date < invalidate
    }
    
    var description: String {
        return name == nil ? "" : name!
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
