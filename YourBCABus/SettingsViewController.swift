//
//  SettingsViewController.swift
//  YourBCABus
//
//  Created by Anthony Li on 10/26/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import UIKit
import UserNotifications

class NotificationSetting {
    let defaultsKey: String
    let readableName: String
    let notificationName: Notification.Name?
    let defaultValue: Bool
    weak var viewController: UIViewController?
    
    init(defaultsKey: String, readableName: String, notificationName: Notification.Name? = nil, defaultValue: Bool = false, viewController: UIViewController? = nil) {
        self.defaultsKey = defaultsKey
        self.readableName = readableName
        self.notificationName = notificationName
        self.defaultValue = defaultValue
        self.viewController = viewController
    }
    
    var value: Bool {
        return UserDefaults.standard.object(forKey: defaultsKey) == nil ? defaultValue : UserDefaults.standard.bool(forKey: defaultsKey)
    }
    
    func changeValue(to value: Bool) {
        UserDefaults.standard.set(value, forKey: defaultsKey)
        UserDefaults.standard.set(true, forKey: MasterViewController.didAskToSetUpNotificationsDefaultsKey)
        
        if let name = notificationName {
            NotificationCenter.default.post(name: name, object: self)
        }
    }
    
    private func displayAlert(switch theSwitch: UISwitch) {
        if let vc = viewController {
            let alert = UIAlertController(title: "Enable Push Notifications", message: "Please enable Push Notifications to receive bus alerts.", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: { action in
                theSwitch.setOn(false, animated: true)
            }))
            
            alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { action in
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
                theSwitch.setOn(false, animated: true)
            }))
            
            vc.present(alert, animated: true)
        }
    }
    
    @objc func switchDidChange(sender: UISwitch) {
        if sender.isOn {
            UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { settings in
                switch settings.authorizationStatus {
                case .denied:
                    self.displayAlert(switch: sender)
                case .notDetermined:
                    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { authorized, error in
                        if authorized {
                            self.changeValue(to: true)
                        } else {
                            self.displayAlert(switch: sender)
                        }
                    })
                default:
                    self.changeValue(to: true)
                }
            })
        } else {
            self.changeValue(to: false)
        }
    }
}

class SettingsViewController: UITableViewController {
    @IBOutlet weak var routeSummarySwitch: UISwitch!
    @IBOutlet weak var useFlyoverMapSwitch: UISwitch!
    
    let routeSummarySetting = NotificationSetting(defaultsKey: AppDelegate.routeSummaryNotificationsDefaultKey, readableName: "", notificationName: AppDelegate.didChangeRouteSummaryNotifications)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        routeSummarySetting.viewController = self
        
        routeSummarySwitch.setOn(routeSummarySetting.value, animated: false)
        routeSummarySwitch.addTarget(routeSummarySetting, action: #selector(NotificationSetting.switchDidChange(sender:)), for: .valueChanged)
        useFlyoverMapSwitch.setOn(UserDefaults.standard.bool(forKey: MapViewController.useFlyoverMapDefaultsKey), animated: false)
        
        // TODO: Better
        UISwitch.appearance().onTintColor = UIColor(named: "Primary")!
    }
    
    @IBAction func done(sender: UIBarButtonItem?) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didChangeUseFlyoverMap(sender: UISwitch?) {
        if let on = sender?.isOn {
            UserDefaults.standard.set(on, forKey: MapViewController.useFlyoverMapDefaultsKey)
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 3 {
            switch indexPath.row {
            case 0:
                openSupport()
            case 1:
                openPrivacyPolicy()
            default:
                break
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func openSupport() {
        UIApplication.shared.open(URL(string: "https://support.yourbcabus.com")!, options: [:], completionHandler: nil)
    }
    
    func openPrivacyPolicy() {
        UIApplication.shared.open(URL(string: "https://support.yourbcabus.com/privacy-policy")!, options: [:], completionHandler: nil)
    }

}
