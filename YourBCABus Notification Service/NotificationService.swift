//
//  NotificationService.swift
//  YourBCABus Notification Service
//
//  Created by Anthony Li on 6/1/19.
//  Copyright © 2019 YourBCABus. All rights reserved.
//

import UserNotifications

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent) ?? UNMutableNotificationContent()
        
        if let bestAttemptContent = bestAttemptContent {
            // Modify the notification content here...
            if request.content.userInfo["dismissal"] != nil {
                bestAttemptContent.title = "It's dismissal time"
                bestAttemptContent.categoryIdentifier = "DISMISSAL_SUMMARY"
                bestAttemptContent.body = "Open the app to check your buses."
                bestAttemptContent.sound = nil
                bestAttemptContent.badge = nil
                
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
