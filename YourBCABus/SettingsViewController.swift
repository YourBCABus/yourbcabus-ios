//
//  SettingsViewController.swift
//  YourBCABus
//
//  Created by Anthony Li on 10/26/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import UIKit
import UserNotifications

class SettingsViewController: UITableViewController {
    @IBOutlet weak var busArrivalNotificationsSwitch: UISwitch!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        busArrivalNotificationsSwitch.setOn(UserDefaults.standard.bool(forKey: AppDelegate.busArrivalNotificationsDefaultKey), animated: false)

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    func enableNotifications() {
        UserDefaults.standard.set(true, forKey: AppDelegate.busArrivalNotificationsDefaultKey)
        UserDefaults.standard.set(true, forKey: MasterViewController.didAskToSetUpNotificationsDefaultsKey)
    }
    
    func displayAlert(switch theSwitch: UISwitch) {
        let alert = UIAlertController(title: "Enable Push Notifications", message: "Please enable Push Notifications to receive bus alerts.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: { action in
            theSwitch.setOn(false, animated: true)
        }))
        
        alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { action in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
            theSwitch.setOn(false, animated: true)
        }))
        
        present(alert, animated: true)
    }
    
    @IBAction func didChangeBusArrivalNotifications(sender: UISwitch?) {
        if let value = sender?.isOn {
            if value {
                UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { settings in
                    switch settings.authorizationStatus {
                    case .denied:
                        self.displayAlert(switch: sender!)
                    case .notDetermined:
                        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { authorized, error in
                            if authorized {
                                self.enableNotifications()
                            } else {
                                self.displayAlert(switch: sender!)
                            }
                        })
                    default:
                        self.enableNotifications()
                    }
                })
            } else {
                UserDefaults.standard.set(false, forKey: AppDelegate.busArrivalNotificationsDefaultKey)
                UserDefaults.standard.set(true, forKey: MasterViewController.didAskToSetUpNotificationsDefaultsKey)
            }
        }
    }
    
    @IBAction func done(sender: UIBarButtonItem?) {
        dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            openSupport()
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func openSupport() {
        UIApplication.shared.open(URL(string: "https://support.yourbcabus.com")!, options: [:], completionHandler: nil)
    }

}
