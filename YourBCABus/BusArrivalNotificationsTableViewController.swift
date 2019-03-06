//
//  BusArrivalNotificationsTableViewController.swift
//  YourBCABus
//
//  Created by Anthony Li on 3/4/19.
//  Copyright © 2019 YourBCABus. All rights reserved.
//

import UIKit

class BusArrivalNotificationsTableViewController: UITableViewController {
    
    class NotificationSetting {
        let defaultsKey: String
        let readableName: String
        let notificationName: Notification.Name?
        let defaultValue: Bool
        
        init(defaultsKey: String, readableName: String, notificationName: Notification.Name? = nil, defaultValue: Bool = false) {
            self.defaultsKey = defaultsKey
            self.readableName = readableName
            self.notificationName = notificationName
            self.defaultValue = defaultValue
        }
        
        var value: Bool {
            return UserDefaults.standard.object(forKey: defaultsKey) == nil ? defaultValue : UserDefaults.standard.bool(forKey: defaultsKey)
        }
        
        func changeValue(to value: Bool) {
            UserDefaults.standard.set(value, forKey: defaultsKey)
            
            if let name = notificationName {
                NotificationCenter.default.post(name: name, object: self)
            }
        }
        
        @objc func switchDidChange(sender: UISwitch) {
            changeValue(to: sender.isOn)
        }
    }
    
    let settings = [
        NotificationSetting(defaultsKey: AppDelegate.busArrivalNotificationsDefaultKey, readableName: "For Starred Buses", notificationName: AppDelegate.didChangeBusArrivalNotifications),
        NotificationSetting(defaultsKey: AppDelegate.routeBusArrivalNotificationsDefaultKey, readableName: "For Current Route", notificationName: AppDelegate.didChangeBusArrivalNotifications)
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TextCell", for: indexPath)

        if cell.accessoryView == nil {
            cell.accessoryView = UISwitch(frame: CGRect.zero)
        }
        
        let setting = settings[indexPath.row]
        
        let switchView = cell.accessoryView as! UISwitch
        switchView.setOn(setting.value, animated: false)
        switchView.removeTarget(nil, action: nil, for: .valueChanged)
        switchView.addTarget(setting, action: #selector(NotificationSetting.switchDidChange(sender:)), for: .valueChanged)
        
        cell.textLabel?.text = setting.readableName

        return cell
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

}