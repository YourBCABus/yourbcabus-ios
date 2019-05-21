//
//  Alerts.swift
//  YourBCABus Embedded
//
//  Created by Anthony Li on 5/20/19.
//  Copyright © 2019 YourBCABus. All rights reserved.
//

import Foundation

public struct Alert: Codable {
    public let _id: String
    public let school_id: String
    public let start_date: Date
    public let end_date: Date
    public let type: AlertType
    public let title: String
    public let content: String
    public let data: AlertData?
    public let can_dismiss: Bool
    
    public struct AlertType: Codable {
        public let name: String
        public let color: AlertColor
    }
    
    public struct AlertColor: Codable, CustomColorConvertible {
        public let name: String?
        public let r: UInt8
        public let g: UInt8
        public let b: UInt8
        public let alpha: UInt8
        
        public struct Components: Codable {
            public let r: UInt8
            public let g: UInt8
            public let b: UInt8
            public let alpha: UInt8
        }
        
        public let appearances: [String: Components]?
        
        public var color: Color {
            if let name = name {
                if let named = Color(named: name) {
                    return named
                }
            }
            
            return Color(red: CGFloat(r) / 255, green: CGFloat(g) / 255, blue: CGFloat(b) / 255, alpha: CGFloat(alpha) / 255)
        }
    }
    
    public struct AlertData: Codable {}
}
