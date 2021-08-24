//
//  GetOffAlertPromptViewController.swift
//  YourBCABus
//
//  Created by Anthony Li on 12/1/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import UIKit
import CoreLocation
import UserNotifications
import YourBCABus_Core

class GetOffAlertPromptViewController: UIViewController, CLLocationManagerDelegate {
    
    struct PermissionsRequired: OptionSet {
        let rawValue: Int
        
        static let locationServices = PermissionsRequired(rawValue: 1 << 0)
        static let pushNotifications = PermissionsRequired(rawValue: 1 << 1)
    }

    @IBOutlet weak var enableButton: UIButton!
    var locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        enableButton?.layer.cornerRadius = 16
        
        locationManager.delegate = self
        
        // Do any additional setup after loading the view.
    }
    
    func enableGetOffAlerts() {
        UserDefaults.standard.set(true, forKey: Constants.getOffAlertsDefaultsKey)
        NotificationCenter.default.post(name: Constants.didChangeGetOffAlertsNotificationName, object: self)
        self.exit()
    }
    
    func displayAlert(permissionsRequired: PermissionsRequired) {
        let title: String
        let message: String
        
        if permissionsRequired == [.pushNotifications] {
            title = "Enable Push Notifications"
            message = "Please enable Push Notifications to receive \"Get Off\" alerts."
        } else if permissionsRequired == [.locationServices] {
            title = "Enable Location Services"
            message = "Please ensure that YourBCABus is Always allowed to use your location."
        } else {
            title = "Check Permissions"
            message = "Please enable Push Notifications and Location Services for YourBCABus."
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: { [weak self] action in
            self?.exit()
        }))
        
        alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { action in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    func locationEnabled() {
        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { settings in
            switch settings.authorizationStatus {
            case .denied:
                DispatchQueue.main.async {
                    self.displayAlert(permissionsRequired: [.pushNotifications])
                }
            case .notDetermined:
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { (authorized, _) in
                    if authorized {
                        DispatchQueue.main.async {
                            self.enableGetOffAlerts()
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.displayAlert(permissionsRequired: [.pushNotifications])
                        }
                    }
                })
            default:
                DispatchQueue.main.async {
                    self.enableGetOffAlerts()
                }
            }
        })
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationAuthorizationDidChange(to: status)
    }
    
    func locationAuthorizationDidChange(to status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            if self.requestingAuthorization {
                if status == .authorizedAlways || status == .authorizedWhenInUse {
                    self.locationEnabled()
                } else {
                    self.displayAlert(permissionsRequired: [.locationServices])
                }
            }
            
            self.requestingAuthorization = false
        }
    }
    
    var requestingAuthorization = false
    
    @IBAction func tryToEnableGetOffAlerts(sender: UIButton?) {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedAlways:
            self.locationEnabled()
        case .notDetermined, .authorizedWhenInUse:
            requestingAuthorization = true
            locationManager.requestAlwaysAuthorization()
        default:
            UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { settings in
                switch settings.authorizationStatus {
                case .denied, .notDetermined:
                    DispatchQueue.main.async {
                        self.displayAlert(permissionsRequired: [.locationServices, .pushNotifications])
                    }
                default:
                    DispatchQueue.main.async {
                        self.displayAlert(permissionsRequired: .locationServices)
                    }
                }
            })
        }
    }
    
    @IBAction func exit(sender: UIButton? = nil) {
        UserDefaults.standard.set(true, forKey: Constants.didAskToSetUpGetOffAlertsDefaultsKey)
        dismiss(animated: true, completion: nil)
    }

}
