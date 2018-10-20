//
//  Models.swift
//  YourBCABus
//
//  Created by Anthony Li on 10/19/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import Foundation

class Bus: Codable {
    let _id: String
    let school_id: String
    let available: Bool
    let name: String?
    let locations: [String]?
    let boarding_time: Date?
    let departure_time: Date?
    let invalidate_time: Date?
    
    func isValidated(asOf date: Date = Date()) -> Bool {
        guard let invalidate = invalidate_time else {
            return false
        }
        
        return date < invalidate
    }
}
