//
//  StopModel.swift
//  StopModel
//
//  Created by Anthony Li on 8/18/21.
//  Copyright © 2021 YourBCABus. All rights reserved.
//

import Foundation

protocol StopModel: Invalidatable {
    var arrivalTime: String? { get }
}

extension StopModel {
    var arrives: Date? {
        arrivalTime.flatMap { isoFormatter.date(from: $0) }
    }
}

extension GetBusDetailsQuery.Data.Bus.Stop: StopModel {}
