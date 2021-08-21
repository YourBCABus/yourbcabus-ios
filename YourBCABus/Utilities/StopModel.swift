//
//  StopModel.swift
//  StopModel
//
//  Created by Anthony Li on 8/18/21.
//  Copyright © 2021 YourBCABus. All rights reserved.
//

import Foundation

protocol StopModel: Invalidatable {
    var name: String? { get }
    var arrivalTime: String? { get }
    var stopLocation: LocationModel? { get }
}

extension StopModel {
    var arrives: Date? {
        arrivalTime.flatMap { isoFormatter.date(from: $0) }
    }
}

extension GetBusDetailsQuery.Data.Bus.Stop.Location: LocationModel {}
extension GetBusDetailsQuery.Data.Bus.Stop: StopModel {
    var stopLocation: LocationModel? {
        location
    }
}
