//
//  BusManager.swift
//  YourBCABus
//
//  Created by Anthony Li on 10/23/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import Foundation

class BusManagerStarListener: Equatable {
    let listener: () -> Void
    init(listener closure: @escaping () -> Void) {
        listener = closure
    }
    
    static func == (a: BusManagerStarListener, b: BusManagerStarListener) -> Bool {
        return a === b
    }
}

class BusManager {
    static var shared = BusManager(defaultsKey: "starredBuses")
    
    init(defaultsKey: String?) {
        if let key = defaultsKey {
            starredDefaultsKey = key
            load()
        }
    }
    
    var starredBuses: [Bus] {
        return _starredBuses
    }
    
    var filteredBuses: [Bus] {
        return _filteredBuses
    }
    
    var buses = [Bus]() {
        didSet {
            _starredBuses = buses.filter { bus in
                return self.isStarred(bus: bus._id)
            }
        }
    }
    var starredDefaultsKey: String?
    
    private var isStarred = [String: Bool]()
    private var _starredBuses = [Bus]()
    private var _filteredBuses = [Bus]()
    private var starListeners = [String: [BusManagerStarListener]]()
    private var starredBusesChangeListeners = [BusManagerStarListener]()
    
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
        starListeners[bus]?.forEach { (listener) in
            listener.listener()
        }
        
        if isStarred[bus] == true {
            if let bus = buses.first(where: {aBus in
                return aBus._id == bus
            }) {
                _starredBuses.append(bus)
                _starredBuses.sort() // TODO: Find a more efficient way to do this
                starredBusesChangeListeners.forEach { listener in
                    listener.listener()
                }
            }
        } else {
            if let index = _starredBuses.firstIndex(where: {aBus in
                return aBus._id == bus
            }) {
                _starredBuses.remove(at: index)
                starredBusesChangeListeners.forEach { listener in
                    listener.listener()
                }
            }
        }
        
        save()
    }
    
    func addStarListener(_ listener: BusManagerStarListener, for bus: String) {
        if starListeners[bus] == nil {
            starListeners[bus] = []
        }
        starListeners[bus]!.append(listener)
    }
    
    func removeStarListener(_ listener: BusManagerStarListener, for bus: String) {
        if let index = starListeners[bus]?.firstIndex(of: listener) {
            starListeners[bus]!.remove(at: index)
        }
    }
    
    func addStarredBusesChangeListener(_ listener: BusManagerStarListener) {
        starredBusesChangeListeners.append(listener)
    }
    
    func removeStarredBusesChangeListener(_ listener: BusManagerStarListener) {
        if let index = starredBusesChangeListeners.firstIndex(of: listener) {
            starredBusesChangeListeners.remove(at: index)
        }
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
