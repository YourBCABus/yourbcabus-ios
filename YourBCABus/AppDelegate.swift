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


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    var window: UIWindow?
    private var notificationTokens = [NotificationToken]()
    
    var schoolId = "5bca51e785aa2627e14db459"
    
    static let busArrivalNotificationsDefaultKey = "busArrivalNotifications"
    static let didChangeBusArrivalNotifications = NSNotification.Name("YBBDidChangeBusArrivalNotifications")

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let splitViewController = window!.rootViewController as! UISplitViewController
        
        let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as! UINavigationController
        navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
        splitViewController.delegate = self
        
        Messaging.messaging().delegate = self
        
        UNUserNotificationCenter.current().delegate = self
        
        application.registerForRemoteNotifications()
        FirebaseApp.configure()
        
        print("YourBCABus FCM registration token length: \(String(describing: Messaging.messaging().fcmToken?.count))")
        
        notificationTokens.append(NotificationCenter.default.observe(name: NSNotification.Name(rawValue: BusManager.NotificationName.starredBusesChange.rawValue), object: nil, queue: nil, using: { [unowned self] notification in
            if UserDefaults.standard.bool(forKey: AppDelegate.busArrivalNotificationsDefaultKey) {
                if let busID = notification.userInfo?[BusManager.NotificationUserInfoKey.busID] as? String {
                    let topic = "school.\(self.schoolId).bus.\(busID)"
                    if BusManager.shared.starredBuses.contains(where: {$0._id == busID}) {
                        Messaging.messaging().subscribe(toTopic: topic)
                    } else {
                        Messaging.messaging().unsubscribe(fromTopic: topic)
                    }
                }
            }
        }))
        
        notificationTokens.append(NotificationCenter.default.observe(name: AppDelegate.didChangeBusArrivalNotifications, object: nil, queue: nil, using: { [unowned self] notification in
            if UserDefaults.standard.bool(forKey: AppDelegate.busArrivalNotificationsDefaultKey) {
                BusManager.shared.starredBuses.forEach { bus in
                    Messaging.messaging().subscribe(toTopic: "school.\(self.schoolId).bus.\(bus._id)")
                }
            } else {
                BusManager.shared.starredBuses.forEach { bus in
                    Messaging.messaging().unsubscribe(fromTopic: "school.\(self.schoolId).bus.\(bus._id)")
                }
            }
        }))
        
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
        DirectionsCache.shared.cache = [:]
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) {
        if let navigation = (window?.rootViewController as? UISplitViewController)?.viewControllers[0] as? UINavigationController {
            if let master = navigation.topViewController as? MasterViewController {
                master.performSegue(withIdentifier: "openSettings", sender: notification)
            }
        }
    }
    
    // MARK: - Split view

    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController:UIViewController, onto primaryViewController:UIViewController) -> Bool {
        /* guard let secondaryAsNavController = secondaryViewController as? UINavigationController else { return false }
        guard let topAsDetailController = secondaryAsNavController.topViewController as? MapViewController else { return false } */
        return true
    }
    
    // MARK: State Restoration
    
    static let versionRestorationKey = "YBBAppVersion"
    
    func application(_ application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
        coder.encode("1.0b1", forKey: AppDelegate.versionRestorationKey)
        return true
    }
    
    func application(_ application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
        guard coder.decodeObject(of: NSString.self, forKey: AppDelegate.versionRestorationKey) == "1.0b1" else {
            return false
        }
        
        return true
    }
    
}

