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
import YourBCABus_Embedded

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {

    var window: UIWindow?
    private var notificationTokens = [NotificationToken]()
    
    var schoolId = Constants.schoolId
    
    static let busArrivalNotificationsDefaultKey = "busArrivalNotifications"
    static let routeBusArrivalNotificationsDefaultKey = "routeBusArrivalNotifications"
    static let routeSummaryNotificationsDefaultKey = "routeSummaryNotifications"
    
    static let didChangeBusArrivalNotifications = NSNotification.Name("YBBDidChangeBusArrivalNotifications")
    static let didChangeRouteSummaryNotifications = NSNotification.Name("YBBDidChangeRouteSummaryNotifications")
        
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        let splitViewController = window!.rootViewController as! UISplitViewController
        
        let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as! UINavigationController
        navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
        navigationController.topViewController!.navigationItem.leftItemsSupplementBackButton = true
        splitViewController.delegate = self
        splitViewController.presentsWithGesture = false
        // splitViewController.preferredDisplayMode = .allVisible
        
        Messaging.messaging().delegate = self
        
        UNUserNotificationCenter.current().delegate = self
        
        application.registerForRemoteNotifications()
        FirebaseApp.configure()
        
        print("YourBCABus FCM registration token length: \(String(describing: Messaging.messaging().fcmToken?.count))") // HACK: Ensures that this app receives an FCM registration token
        
        notificationTokens.append(NotificationCenter.default.observe(name: NSNotification.Name(rawValue: BusManager.NotificationName.starredBusesChange.rawValue), object: nil, queue: nil, using: { [unowned self] notification in
            if UserDefaults.standard.bool(forKey: AppDelegate.busArrivalNotificationsDefaultKey) {
                if let busID = notification.userInfo?[BusManager.NotificationUserInfoKey.busID] as? String {
                    let topic = "school.\(self.schoolId).bus.\(busID)"
                    if BusManager.shared.starredBuses.contains(where: {$0._id == busID}) {
                        Messaging.messaging().subscribe(toTopic: topic)
                    } else {
                        var routeBusId: String?
                    
                        if let data = UserDefaults(suiteName: Constants.groupId)?.data(forKey: Constants.currentDestinationDefaultsKey) {
                            let route = try? PropertyListDecoder().decode(Route.self, from: data)
                            routeBusId = route?.bus?._id
                        }

                        if busID != routeBusId {
                            Messaging.messaging().unsubscribe(fromTopic: topic)
                        }
                    }
                }
            }
        }))
        
        notificationTokens.append(NotificationCenter.default.observe(name: MasterViewController.currentDestinationDidChange, object: nil, queue: nil, using: { [unowned self] notification in
            if UserDefaults.standard.bool(forKey: AppDelegate.routeBusArrivalNotificationsDefaultKey) {
                if let oldID = (notification.userInfo?[MasterViewController.currentDestinationDidChangeOldRouteKey] as? Route)?.bus?._id {
                    if !BusManager.shared.starredBuses.contains(where: {$0._id == oldID}) {
                        Messaging.messaging().unsubscribe(fromTopic: "school.\(self.schoolId).bus.\(oldID)")
                    }
                }
                
                if let id = (notification.userInfo?[MasterViewController.currentDestinationDidChangeNewRouteKey] as? Route)?.bus?._id {
                    Messaging.messaging().subscribe(toTopic: "school.\(self.schoolId).bus.\(id)")
                }
            }
        }))
        
        notificationTokens.append(NotificationCenter.default.observe(name: AppDelegate.didChangeBusArrivalNotifications, object: nil, queue: nil, using: { [unowned self] notification in
            var allBuses = Set<String>()
            var toStar = Set<String>()
            
            if let data = UserDefaults(suiteName: Constants.groupId)?.data(forKey: Constants.currentDestinationDefaultsKey) {
                let route = try? PropertyListDecoder().decode(Route.self, from: data)
                if let id = route?.bus?._id {
                    allBuses.insert(id)
                    if UserDefaults.standard.bool(forKey: AppDelegate.routeBusArrivalNotificationsDefaultKey) {
                        toStar.insert(id)
                    }
                }
            }

            BusManager.shared.starredBuses.forEach { bus in
                allBuses.insert(bus._id)
            }
            
            if UserDefaults.standard.bool(forKey: AppDelegate.busArrivalNotificationsDefaultKey) {
                BusManager.shared.starredBuses.forEach { bus in
                    toStar.insert(bus._id)
                }
            }

            assert(allBuses.isSuperset(of: toStar))
            
            toStar.forEach { bus in
                Messaging.messaging().subscribe(toTopic: "school.\(self.schoolId).bus.\(bus)")
            }
            
            allBuses.subtracting(toStar).forEach { bus in
                Messaging.messaging().unsubscribe(fromTopic: "school.\(self.schoolId).bus.\(bus)")
            }
            
            UserDefaults.standard.set(true, forKey: MasterViewController.didAskToSetUpNotificationsDefaultsKey)
        }))
        
        notificationTokens.append(NotificationCenter.default.observe(name: AppDelegate.didChangeRouteSummaryNotifications, object: nil, queue: nil, using: { _ in
            if UserDefaults.standard.bool(forKey: AppDelegate.routeBusArrivalNotificationsDefaultKey) {
                Messaging.messaging().subscribe(toTopic: "school.\(self.schoolId).dismissal.banner")
            } else {
                Messaging.messaging().unsubscribe(fromTopic: "school.\(self.schoolId).dismissal.banner")
            }
        }))
        
        UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { requests in
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: requests.filter({ $0.identifier.starts(with: ModalNavigationViewController.getOffAlertNotificationIdPrefix) }).map({ $0.identifier }))
        })
        
        if UserDefaults.standard.bool(forKey: AppDelegate.busArrivalNotificationsDefaultKey) && UserDefaults.standard.object(forKey: AppDelegate.routeBusArrivalNotificationsDefaultKey) == nil {
            UserDefaults.standard.set(true, forKey: AppDelegate.routeBusArrivalNotificationsDefaultKey)
            NotificationCenter.default.post(name: AppDelegate.didChangeBusArrivalNotifications, object: nil)
        }
        
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
        DirectionsCache.shared.clearCache()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, openSettingsFor notification: UNNotification?) {
        if let navigation = (window?.rootViewController as? UISplitViewController)?.viewControllers[0] as? UINavigationController {
            if let master = navigation.topViewController as? MasterViewController {
                master.performSegue(withIdentifier: "openSettings", sender: notification)
            }
        }
    }
    
    // MARK: - Split view
    
    private var didPerformInitialCollapse = false

    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController:UIViewController, onto primaryViewController:UIViewController) -> Bool {
        let didPerform = didPerformInitialCollapse
        didPerformInitialCollapse = true
        return !didPerform
    }
    
    // MARK: State Restoration
    
    static let versionRestorationKey = "YBBAppVersion"
    var versionRestorationValue = "1.0b7"
    
    func application(_ application: UIApplication, shouldSaveApplicationState coder: NSCoder) -> Bool {
        /* coder.encode(versionRestorationValue, forKey: AppDelegate.versionRestorationKey)
        return true */
        return false
    }
    
    func application(_ application: UIApplication, shouldRestoreApplicationState coder: NSCoder) -> Bool {
        /* let version = coder.decodeObject(of: NSString.self, forKey: AppDelegate.versionRestorationKey)
        if version == "1.0b1" || version == "1.0b5" {
            shouldShowNotificationsAlert = true
        }
        
        if version != versionRestorationValue as NSString {
            return false
        }
        
        return true */
        return false
    }
    
}

extension UIApplication {
    func openSettings() {
        open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
    }
}
