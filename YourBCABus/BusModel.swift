//
//  BusModel.swift
//  YourBCABus
//
//  Created by Anthony Li on 8/9/21.
//  Copyright © 2021 YourBCABus. All rights reserved.
//

import Foundation

protocol BusModel {
    var id: String { get }
    var boardingArea: String? { get }
    var invalidateTime: String? { get }
}

let formatter = ISO8601DateFormatter()

extension BusModel {
    var invalidates: Date? {
        invalidateTime.flatMap { formatter.date(from: $0) }
    }
    
    func isValidated(at date: Date = Date()) -> Bool {
        if let invalidates = invalidates, invalidates < date {
            return false
        } else {
            return true
        }
    }
    
    func getBoardingArea(at date: Date = Date()) -> String? {
        return isValidated(at: date) ? boardingArea : nil
    }
}

extension GetBusesQuery.Data.School.Bus: BusModel {}
