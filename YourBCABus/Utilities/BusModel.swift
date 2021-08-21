//
//  BusModel.swift
//  YourBCABus
//
//  Created by Anthony Li on 8/9/21.
//  Copyright © 2021 YourBCABus. All rights reserved.
//

import Foundation

protocol Invalidatable {
    var invalidateTime: String? { get }
}

let isoFormatter = ISO8601DateFormatter()

extension Invalidatable {
    var invalidates: Date? {
        invalidateTime.flatMap { isoFormatter.date(from: $0) }
    }
    
    func isValidated(at date: Date = Date()) -> Bool {
        if let invalidates = invalidates, invalidates < date {
            return false
        } else {
            return true
        }
    }
}

protocol BusModel: Invalidatable {
    var id: String { get }
    var name: String? { get }
    var boardingArea: String? { get }
    var available: Bool { get }
}

extension BusModel {
    func getBoardingArea(at date: Date = Date()) -> String? {
        return isValidated(at: date) ? boardingArea : nil
    }
    
    func status(at date: Date = Date()) -> String {
        if boardingArea != nil {
            return "Arrived"
        } else if available {
            return "Not at school"
        } else {
            return "Not running"
        }
    }
}

extension GetBusesQuery.Data.School.Bus: BusModel {}

func busPredicate(for search: String) -> NSPredicate {
    var predicates = [NSPredicate]()
    let stringExpression = NSExpression(forConstantValue: search)
    
    let nameExpression = NSExpression(block: { (bus, _, _) in
        return (bus as! BusModel).name ?? "(unnamed bus)"
    }, arguments: nil)
    let namePredicate = NSComparisonPredicate(leftExpression: nameExpression, rightExpression: stringExpression, modifier: .direct, type: .contains, options: [.caseInsensitive, .diacriticInsensitive])
    predicates.append(namePredicate)
    
    let idExpression = NSExpression(block: { (bus, _, _) in
        return (bus as! BusModel).id
    }, arguments: nil)
    let idPredicate = NSComparisonPredicate(leftExpression: idExpression, rightExpression: stringExpression, modifier: .direct, type: .equalTo, options: [.caseInsensitive, .diacriticInsensitive])
    predicates.append(idPredicate)
    
    let now = Date()
    let boardingAreaExpression = NSExpression(block: { (bus, _, _) in
        return (bus as! BusModel).getBoardingArea(at: now) ?? "?"
    }, arguments: nil)
    let boardingAreaPredicate = NSComparisonPredicate(leftExpression: boardingAreaExpression, rightExpression: stringExpression, modifier: .direct, type: .equalTo, options: [.caseInsensitive, .diacriticInsensitive])
    predicates.append(boardingAreaPredicate)
    
    return NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
}
