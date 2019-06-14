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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UISplitViewControllerDelegate, UNUserNotificationCenterDelegate, CLLocationManagerDelegate, MessagingDelegate {

    var window: UIWindow?
    
    private var notificationTokens = [NotificationToken]()
    
    var schoolId = Constants.schoolId
    
    static let busArrivalNotificationsDefaultKey = "busArrivalNotifications"
    static let routeBusArrivalNotificationsDefaultKey = "routeBusArrivalNotifications"
    static let routeSummaryNotificationsDefaultKey = "routeSummaryNotifications"
    
    static let didChangeBusArrivalNotifications = NSNotification.Name("YBBDidChangeBusArrivalNotifications")
    static let didChangeRouteSummaryNotifications = NSNotification.Name("YBBDidChangeRouteSummaryNotifications")
    
    let locationManager = CLLocationManager()
        
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        locationManager.delegate = self
        
        // Override point for customization after application launch.
        
        if #available(iOS 13.0, UIKitForMac 13.0, *) {
            
        } else {
            let splitViewController = window!.rootViewController as! UISplitViewController
            let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as! UINavigationController
            navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
            navigationController.topViewController!.navigationItem.leftItemsSupplementBackButton = true
            splitViewController.delegate = self
            splitViewController.presentsWithGesture = false
            // splitViewController.preferredDisplayMode = .allVisible
        }
        
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
        
        notificationTokens.append(NotificationCenter.default.observe(name: Constants.didChangeGetOffAlertsNotificationName, object: nil, queue: nil, using: { [weak self] _ in
            self?.configureGetOffAlerts()
        }))
        
        return true
    }
    
    func configureGetOffAlerts() {
        locationManager.monitoredRegions.forEach(locationManager.stopMonitoring)
        if UserDefaults.standard.bool(forKey: Constants.getOffAlertsDefaultsKey) {
            if let data = UserDefaults(suiteName: Constants.groupId)?.data(forKey: Constants.currentDestinationDefaultsKey) {
                if let route = try? PropertyListDecoder().decode(Route.self, from: data) {
                    if let stop = route.stop {
                        let radius = CLLocationDistance(UserDefaults.standard.integer(forKey: Constants.getOffAlertRadiusDefaultKey))
                        locationManager.startMonitoring(for: CLCircularRegion(center: CLLocationCoordinate2D(from: stop.location), radius: radius == 0 ? Constants.getOffAlertDefaultRadius : radius, identifier: stop._id))
                    }
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        APIService.shared.getSchool(schoolId: Constants.schoolId, cachingMode: .forceFetch, { schoolResult in
            if let zoneName = schoolResult.result?.timezone, let zone = TimeZone(identifier: zoneName) {
                let date = Date()
                APIService.shared.getDismissal(schoolId: Constants.schoolId, date: date, { dismissalResult in
                    if let start = dismissalResult.result?.start_time, let end = dismissalResult.result?.end_time {
                        let calendar = Calendar(identifier: .gregorian)
                        let components = calendar.dateComponents(in: zone, from: date)
                        let time = components.hour! * 3600 + components.minute! * 60 + components.second!
                        if (start...end).contains(time) {
                            let content = UNMutableNotificationContent()
                            content.title = "Get off soon"
                            content.body = "You've arrived at your stop."
                            content.sound = .default
                            UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "com.yourbcabus.yourbcabus-ios.alert.get-off", content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)), withCompletionHandler: nil)
                        }
                    }
                })
            }
        })
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
