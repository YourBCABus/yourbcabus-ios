//
//  GetOffAlertEventReceiver.swift
//  YourBCABus
//
//  Created by Anthony Li on 12/1/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import Foundation
import CoreLocation

@objc protocol GetOffAlertEventReceiver {
    func setLocationManager(_ manager: CLLocationManager)
    @objc optional func locationAuthorizationDidChange(to status: CLAuthorizationStatus)
}
