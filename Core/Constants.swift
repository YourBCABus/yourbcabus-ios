//
//  Constants.swift
//  YourBCABus Embedded
//
//  Created by Anthony Li on 5/15/19.
//  Copyright © 2019 YourBCABus. All rights reserved.
//

import CoreLocation

public struct Constants {
    private init() {}
    
    public static let groupId = "group.com.yourbcabus.yourbcabus"
    public static let currentDestinationDefaultsKey = "currentDestination"
    public static let schoolId = "5bca51e785aa2627e14db459"
    
    public static let getOffAlertsDefaultsKey = "stopArrivalNotificationsEnabled"
    public static let getOffAlertRadiusDefaultKey = "stopArrivalNotificationsRadius"
    public static let getOffAlertDefaultRadius: CLLocationDistance = 500
    public static let didAskToSetUpGetOffAlertsDefaultsKey = "didAskToSetUpStopArrivalNotifications"
    public static let didChangeGetOffAlertsNotificationName = Notification.Name("YBBDidChangeGetOffAlerts")
    public static let getOffAlertNotificationIdPrefix = "YBBGetOffAlert"
}
