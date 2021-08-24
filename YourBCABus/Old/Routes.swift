//
//  Routes.swift
//  YourBCABus
//
//  Created by Anthony Li on 11/7/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import Foundation
import MapKit

public class Route: Codable {
    enum CodingKeys: String, CodingKey {
        case stop
        case bus
        case schoolId
    }
    
    public var stop: Stop?
    public let schoolId: String
    public var bus: Bus?
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(stop, forKey: .stop)
        try container.encode(schoolId, forKey: .schoolId)
        try container.encode(bus, forKey: .bus)
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        if container.contains(.stop) {
            stop = try container.decode(Stop?.self, forKey: .stop)
        } else {
            stop = nil
        }
        if container.contains(.bus) {
            bus = try container.decode(Bus?.self, forKey: .bus)
        } else {
            bus = nil
        }
        schoolId = try container.decode(String.self, forKey: .schoolId)
    }
}

public extension MKMapRect {
    init(a: MKMapPoint, b: MKMapPoint) {
        self.init(x: min(a.x, b.x), y: min(a.y, b.y), width: abs(a.x - b.x), height: abs(a.y - b.y))
    }
}
