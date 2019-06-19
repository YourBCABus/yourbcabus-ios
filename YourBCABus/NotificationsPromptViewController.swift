//
//  NotificationsPromptViewController.swift
//  YourBCABus
//
//  Created by Anthony Li on 11/14/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import UIKit
import UserNotifications

class NotificationsPromptViewController: UIViewController {
    
    @IBOutlet weak var enableButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        enableButton?.layer.cornerRadius = 16

        // Do any additional setup after loading the view.
    }
    
    func enableNotifications() {
        UserDefaults.standard.set(true, forKey: AppDelegate.busArrivalNotificationsDefaultKey)
        UserDefaults.standard.set(true, forKey: AppDelegate.routeBusArrivalNotificationsDefaultKey)
        UserDefaults.standard.set(true, forKey: AppDelegate.routeSummaryNotificationsDefaultKey)
        NotificationCenter.default.post(name: AppDelegate.didChangeBusArrivalNotifications, object: self)
        NotificationCenter.default.post(name: AppDelegate.didChangeRouteSummaryNotifications, object: self)
        self.exit()
    }
    
    func displayAlert() {
        let alert = UIAlertController(title: "Enable Push Notifications", message: "Please enable Push Notifications to receive bus alerts.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Close", style: .cancel, handler: { [weak self] action in
            self?.exit()
        }))
        
        alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { action in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
        }))
        
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func tryToEnableNotifications(sender: UIButton?) {
        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { settings in
            switch settings.authorizationStatus {
            case .denied:
                DispatchQueue.main.async {
                    self.displayAlert()
                }
            case .notDetermined:
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { authorized, error in
                    DispatchQueue.main.async {
                        if authorized {
                            self.enableNotifications()
                        } else {
                            self.displayAlert()
                        }
                    }
                })
            default:
                DispatchQueue.main.async {
                    self.enableNotifications()
                }
            }
        })
    }
    
    @IBAction func exit(sender: UIButton? = nil) {
        UserDefaults.standard.set(true, forKey: MasterViewController.didAskToSetUpNotificationsDefaultsKey)
        dismiss(animated: true, completion: nil)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
