//
//  GetOffAlertSettingsViewController.swift
//  YourBCABus
//
//  Created by Anthony Li on 12/5/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import UIKit
import CoreLocation
import UserNotifications

class GetOffAlertSettingsViewController: UITableViewController, CLLocationManagerDelegate {
    
    enum RequiredStep {
        case enableNotifications
        case enableLocationServices
    }
    
    enum Section {
        case requiredSteps
        case getOffAlertToggle
    }
    
    var requiredSteps = [RequiredStep]() {
        willSet {
            if newValue.count == 0 && requiredSteps.count > 0 {
                NotificationCenter.default.post(name: ModalNavigationViewController.didChangeGetOffAlertsNotificationName, object: self)
            }
        }
    }
    var getOffAlertsAvailable = true
    
    private var checkNotificationsTimer: Timer?
    private var locationManager = CLLocationManager()
    
    private var sections: [Section] {
        if getOffAlertsAvailable && requiredSteps.count > 0 {
            return [.requiredSteps, .getOffAlertToggle]
        } else {
            return [.getOffAlertToggle]
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
            
        if navigationController?.viewControllers.first === self {
            let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(exit(sender:)))
            doneButton.tintColor = .white
            navigationItem.rightBarButtonItem = doneButton
        }
        
        getOffAlertsAvailable = CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self)
        
        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .denied, .provisional, .notDetermined:
                    self.checkNotificationsTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true, block: { [weak self] timer in
                        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { settings in
                            if settings.authorizationStatus == .authorized {
                                self?.checkNotificationsTimer?.invalidate()
                                DispatchQueue.main.async {
                                    if let index = self?.requiredSteps.firstIndex(of: .enableNotifications) {
                                        self?.requiredSteps.remove(at: index)
                                        self?.tableView.reloadData()
                                    }
                                }
                            }
                        })
                    })
                    self.requiredSteps.append(.enableNotifications)
                    self.tableView.reloadData()
                default:
                    break
                }
            }
        })
        
        if CLLocationManager.authorizationStatus() != .authorizedWhenInUse && CLLocationManager.authorizationStatus() != .authorizedAlways {
            self.requiredSteps.append(.enableLocationServices)
        }
    }
    
    @objc func exit(sender: UIView?) {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch sections[section] {
        case .requiredSteps:
            return "Required Steps"
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch sections[section] {
        case .requiredSteps:
            return "Before enabling Get Off Alerts, you must complete these steps."
        case .getOffAlertToggle:
            return getOffAlertsAvailable ? nil : "Get Off Alerts are unavailable on your device."
        default:
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
        case .requiredSteps:
            return requiredSteps.count
        default:
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch sections[indexPath.section] {
        case .requiredSteps:
            let cell = tableView.dequeueReusableCell(withIdentifier: "DisclosureCell")!
            let step = requiredSteps[indexPath.row]
            
            switch step {
            case .enableNotifications:
                cell.textLabel!.text = "Allow Notifications"
            case .enableLocationServices:
                cell.textLabel!.text = "Enable Location Services for YourBCABus (Always)"
            default:
                break
            }
            
            return cell
        case .getOffAlertToggle:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchCell")!
            if !(cell.accessoryView is UISwitch) {
                let theSwitch = UISwitch(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
                theSwitch.addTarget(self, action: #selector(getOffAlertSwitchChanged(sender:)), for: .valueChanged)
                cell.accessoryView = theSwitch
            }
            
            let switchView = cell.accessoryView as! UISwitch
            switchView.isEnabled = getOffAlertsAvailable && requiredSteps.count < 1
            switchView.setOn(UserDefaults.standard.bool(forKey: ModalNavigationViewController.getOffAlertsDefaultsKey), animated: false)
            
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "DisclosureCell")!
            cell.textLabel!.text = nil
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch sections[indexPath.section] {
        case .requiredSteps:
            switch requiredSteps[indexPath.row] {
            case .enableLocationServices:
                switch CLLocationManager.authorizationStatus() {
                case .notDetermined, .authorizedWhenInUse:
                    locationManager.requestAlwaysAuthorization()
                default:
                    UIApplication.shared.openSettings()
                }
            case .enableNotifications:
                UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { settings in
                    DispatchQueue.main.async {
                        switch settings.authorizationStatus {
                        case .provisional, .notDetermined:
                            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound], completionHandler: { (authorized, error) in
                                if authorized {
                                    DispatchQueue.main.async {
                                        self.checkNotificationsTimer?.invalidate()
                                        if let index = self.requiredSteps.firstIndex(of: .enableNotifications) {
                                            self.requiredSteps.remove(at: index)
                                            self.tableView.reloadData()
                                        }
                                    }
                                }
                            })
                        default:
                            UIApplication.shared.openSettings()
                        }
                    }
                })
                break
            default:
                break
            }
            
            tableView.deselectRow(at: indexPath, animated: true)
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        DispatchQueue.main.async {
            if status == .authorizedAlways || status == .authorizedWhenInUse {
                if let index = self.requiredSteps.firstIndex(of: .enableLocationServices) {
                    self.requiredSteps.remove(at: index)
                    self.tableView.reloadData()
                }
            } else if !self.requiredSteps.contains(.enableLocationServices) {
                self.requiredSteps.append(.enableLocationServices)
                self.tableView.reloadData()
            }
        }
    }
    
    @objc func getOffAlertSwitchChanged(sender: UISwitch?) {
        UserDefaults.standard.set(true, forKey: ModalNavigationViewController.didAskToSetUpGetOffAlertsDefaultsKey)
        
        guard let theSwitch = sender else { return }
        
        UserDefaults.standard.set(theSwitch.isOn, forKey: ModalNavigationViewController.getOffAlertsDefaultsKey)
        NotificationCenter.default.post(name: ModalNavigationViewController.didChangeGetOffAlertsNotificationName, object: self)
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    deinit {
        checkNotificationsTimer?.invalidate()
    }

}
