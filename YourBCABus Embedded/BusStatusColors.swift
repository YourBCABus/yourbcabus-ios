//
//  BusStatusColors.swift
//  YourBCABus
//
//  Created by Anthony Li on 2/26/19.
//  Copyright © 2019 YourBCABus. All rights reserved.
//

import UIKit

public typealias Color = UIColor

public protocol CustomColorConvertible {
    var color: Color { get }
}

extension BusStatus: CustomColorConvertible {
    public var color: Color {
        switch self {
        case .unavailable:
            return Color.darkGray
        case .notArrived(let boarding):
            if let time = boarding {
                if time < 150 {
                    return Color(named: "Bucket 0")!
                } else if time <= 600 {
                    return Color(named: "Bucket 1")!
                } else if time <= 900 {
                    return Color(named: "Bucket 2")!
                } else if time < 1200 {
                    return Color(named: "Bucket 3")!
                } else {
                    return Color(named: "Bucket 4")!
                }
            }
            
            return Color.lightGray
        case .arrived:
            return Color(named: "Accent")!
        }
    }
}
