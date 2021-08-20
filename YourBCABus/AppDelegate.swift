//
//  AppDelegate.swift
//  YourBCABus
//
//  Created by Anthony Li on 10/19/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import UIKit
import Firebase
import UserNotifications
import CoreLocation
import YourBCABus_Embedded

class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate, ObservableObject {
    static let busArrivalNotificationsDefaultKey = "busArrivalNotifications"
    static let routeBusArrivalNotificationsDefaultKey = "routeBusArrivalNotifications"
    static let routeSummaryNotificationsDefaultKey = "routeSummaryNotifications"
    
    static let didChangeBusArrivalNotifications = NSNotification.Name("YBBDidChangeBusArrivalNotifications")
    static let didChangeRouteSummaryNotifications = NSNotification.Name("YBBDidChangeRouteSummaryNotifications")
            
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        application.registerForRemoteNotifications()
        print("YourBCABus FCM registration token length: \(String(describing: Messaging.messaging().fcmToken?.count))") // HACK: Ensures that this app receives an FCM registration token
        
        Messaging.messaging().subscribe(toTopic: "global")
        Messaging.messaging().subscribe(toTopic: "global.ios")
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) {
        
    }
    
    func subscribe(busIDs: Set<String>) {
        busIDs.forEach { id in
            Messaging.messaging().subscribe(toTopic: "bus.\(id)")
        }
    }
    
    func unsubscribe(busIDs: Set<String>) {
        busIDs.forEach { id in
            Messaging.messaging().unsubscribe(fromTopic: "bus.\(id)")
        }
    }
}

extension UIApplication {
    func openSettings() {
        open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
    }
}
