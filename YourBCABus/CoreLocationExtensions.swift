//
//  CoreLocationExtensions.swift
//  YourBCABus
//
//  Created by Anthony Li on 12/8/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import CoreLocation

extension CLLocationCoordinate2D: Equatable {
    public static func == (a: CLLocationCoordinate2D, b: CLLocationCoordinate2D) -> Bool {
        return a.latitude == b.latitude && a.longitude == b.longitude
    }
}
