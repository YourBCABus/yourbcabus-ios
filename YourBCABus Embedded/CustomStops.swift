//
//  CustomStops.swift
//  YourBCABus
//
//  Created by Anthony Li on 12/8/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import Foundation

public extension Stop {
    static let customStopsDefaultsKey = "YBBCustomStops"
    
    static func getCustomStops(withUserDefaults userDefaults: UserDefaults = UserDefaults.standard) throws -> [Stop] {
        if let data = userDefaults.data(forKey: Stop.customStopsDefaultsKey) {
            let decoder = PropertyListDecoder()
            return try decoder.decode([Stop].self, from: data)
        } else {
            return []
        }
    }
    
    static func saveCustomStops(_ stops: [Stop], withUserDefaults userDefaults: UserDefaults = UserDefaults.standard) throws {
        let encoder = PropertyListEncoder()
        userDefaults.set(try encoder.encode(stops), forKey: Stop.customStopsDefaultsKey)
    }
}
