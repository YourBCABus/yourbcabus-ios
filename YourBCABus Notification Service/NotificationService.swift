//
//  NotificationService.swift
//  YourBCABus Notification Service
//
//  Created by Anthony Li on 6/1/19.
//  Copyright © 2019 YourBCABus. All rights reserved.
//

import UserNotifications
import YourBCABus_Embedded

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?
    
    let dateFormatter = DateFormatter()
    
    override init() {
        super.init()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short
    }
    
    func stringForRoute(_ route: Route) -> String {
        var result = ""
        
        if let bus = route.bus {
            if let name = bus.name {
                result += "Your bus to \(name) is "
            } else {
                result += "Your bus is "
            }
            
            if let location = bus.location {
                result += "at \(location). "
            } else {
                result += "not here yet. "
            }
        } else {
            result += "You're walking. "
        }
        
        let destination = route.destination.name ?? "your destination"
        if let eta = route.eta {
            result += "You'll arrive at \(destination) around \(dateFormatter.string(from: eta))."
        } else {
            result += "You're going to \(destination)."
        }
        
        return result
    }

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent) ?? UNMutableNotificationContent()
        
        if let bestAttemptContent = bestAttemptContent {
            // Modify the notification content here...
            if request.content.userInfo["dismissal"] != nil {
                bestAttemptContent.title = "Route Summary"
                bestAttemptContent.categoryIdentifier = "DISMISSAL_SUMMARY"
                bestAttemptContent.body = "Open the app to add a destination."
                
                if let routeData = UserDefaults(suiteName: Constants.groupId)?.data(forKey: Constants.currentDestinationDefaultsKey) {
                    if let route = try? PropertyListDecoder().decode(Route.self, from: routeData) {
                        bestAttemptContent.body = stringForRoute(route)
                        route.fetchData { [weak self] (_, _, _) in
                            if let self = self {
                                bestAttemptContent.body = self.stringForRoute(route)
                            }
                            if let data = try? PropertyListEncoder().encode(route) {
                                UserDefaults(suiteName: Constants.groupId)?.set(data, forKey: Constants.currentDestinationDefaultsKey)
                            }
                        }
                    }
                }
                
                contentHandler(bestAttemptContent)
            } else {
                contentHandler(request.content)
            }
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

}
