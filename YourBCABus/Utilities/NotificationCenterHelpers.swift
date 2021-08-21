//
//  NotificationCenterHelpers.swift
//  YourBCABus
//
//  Created by Anthony Li on 10/25/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import Foundation

final class NotificationToken: NSObject {
    let notificationCenter: NotificationCenter
    let token: Any
    
    init(notificationCenter: NotificationCenter = .default, token: Any) {
        self.notificationCenter = notificationCenter
        self.token = token
    }
    
    deinit {
        notificationCenter.removeObserver(token)
    }
}

extension NotificationCenter {
    /// Convenience wrapper for addObserver(forName:object:queue:using:)
    /// that returns our custom NotificationToken.
    func observe(name: NSNotification.Name?, object obj: Any?,
                 queue: OperationQueue?, using block: @escaping (Notification) -> ())
        -> NotificationToken
    {
        let token = addObserver(forName: name, object: obj, queue: queue, using: block)
        return NotificationToken(notificationCenter: self, token: token)
    }
}

