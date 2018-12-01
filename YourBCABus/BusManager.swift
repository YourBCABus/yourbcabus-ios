//
//  BusManager.swift
//  YourBCABus
//
//  Created by Anthony Li on 10/23/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import Foundation

class BusManager {
    static var shared = BusManager(defaultsKey: "starredBuses")
    
    enum NotificationName: String {
        case starredBusesChange = "YBBStar"
        case busesChange = "YBBBusesChange"
    }
    
    enum NotificationUserInfoKey {
        case busID
    }
    
    init(defaultsKey: String?) {
        if let key = defaultsKey {
            starredDefaultsKey = key
            load()
        }
        
        notificationTokens.append(notificationCenter.observe(name: Notification.Name(NotificationName.busesChange.rawValue), object: self, queue: nil, using: { [unowned self] notification in
            self._starredBuses = self.buses.filter { self.isStarred(bus: $0._id) }
        }))
    }
    
    var starredBuses: [Bus] {
        return _starredBuses
    }
    
    var starredBusIDs: [String] {
        return Array(isStarred.filter({ $1 }).keys)
    }
    
    var filteredBuses: [Bus] {
        return _filteredBuses
    }
    
    var buses = [Bus]()
    
    var starredDefaultsKey: String?
    var notificationCenter = NotificationCenter.default
    
    private var isStarred = [String: Bool]()
    private var _starredBuses = [Bus]()
    private var _filteredBuses = [Bus]()
    private var notificationTokens = [NotificationToken]()
    
    private func load() {
        if let key = starredDefaultsKey {
            if let dict = UserDefaults.standard.dictionary(forKey: key) as? [String: Bool] {
                isStarred = dict
            }
        }
    }
    
    private func save() {
        if let key = starredDefaultsKey {
            UserDefaults.standard.set(isStarred, forKey: key)
        }
    }
    
    func toggleStar(for bus: String) {
        isStarred[bus] = isStarred[bus] != true
        
        if isStarred[bus] == true {
            if let bus = buses.first(where: {aBus in
                return aBus._id == bus
            }) {
                _starredBuses.append(bus)
                _starredBuses.sort() // TODO: Find a more efficient way to do this
            }
        } else {
            if let index = _starredBuses.firstIndex(where: {aBus in
                return aBus._id == bus
            }) {
                _starredBuses.remove(at: index)
            }
        }
        
        notificationCenter.post(name: NSNotification.Name(NotificationName.starredBusesChange.rawValue), object: self, userInfo: [NotificationUserInfoKey.busID: bus])
        save()
    }
    
    func busesUpdated() {
        notificationCenter.post(name: NSNotification.Name(NotificationName.busesChange.rawValue), object: self)
    }
    
    func isStarred(bus: String) -> Bool {
        return isStarred[bus] == true
    }
        
    func searchPredicate(for string: String) -> NSCompoundPredicate {
        var predicate = [NSPredicate]()
        
        let stringExpression = NSExpression(forConstantValue: string)
        
        let nameExpression = NSExpression(block: { (bus, _, _) in
            return (bus as! Bus).description
        }, arguments: nil)
        let namePredicate = NSComparisonPredicate(leftExpression: nameExpression, rightExpression: stringExpression, modifier: .direct, type: .contains, options: [.caseInsensitive, .diacriticInsensitive])
        predicate.append(namePredicate)
        
        let locationExpression = NSExpression(block: { (bus, _, _) in
            if let loc = (bus as! Bus).location {
                return loc
            } else {
                return ""
            }
        }, arguments: nil)
        let locationPredicate = NSComparisonPredicate(leftExpression: locationExpression, rightExpression: stringExpression, modifier: .direct, type: .equalTo, options: [.caseInsensitive, .diacriticInsensitive])
        predicate.append(locationPredicate)
        
        return NSCompoundPredicate(orPredicateWithSubpredicates: predicate)
    }
    
    func updateFilteredBuses(term: String, using: NSPredicate? = nil) {
        let predicate: NSPredicate = using == nil ? searchPredicate(for: term) : using!
        _filteredBuses = buses.filter { predicate.evaluate(with: $0) }
    }
}
