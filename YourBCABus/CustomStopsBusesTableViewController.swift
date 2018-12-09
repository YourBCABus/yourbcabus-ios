//
//  CustomStopsBusesTableViewController.swift
//  YourBCABus
//
//  Created by Anthony Li on 12/8/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import UIKit

class CustomStopsBusesTableViewController: UITableViewController {
    
    private var notificationTokens = [NotificationToken]()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        notificationTokens.append(NotificationCenter.default.observe(name: NSNotification.Name(BusManager.NotificationName.busesChange.rawValue), object: nil, queue: nil, using: { [unowned self] notification in
            self.tableView.reloadData()
        }))
        
        notificationTokens.append(NotificationCenter.default.observe(name: NSNotification.Name(BusManager.NotificationName.starredBusesChange.rawValue), object: nil, queue: nil, using: { [unowned self] notification in
            self.tableView.reloadData()
        }))
    }
    
    @IBAction func exit(sender: Any?) {
        dismiss(animated: true, completion: nil)
    }

    // MARK: - Table view data source
    
    var showsStarredBuses: Bool {
        return BusManager.shared.starredBuses.count > 0
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return showsStarredBuses ? 3 : 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        
        if showsStarredBuses && section == 1 {
            return BusManager.shared.starredBuses.count
        }
        
        return BusManager.shared.buses.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if showsStarredBuses {
            if section == 1 {
                return "Starred Buses"
            } else if section == 2 {
                return "All Buses"
            }
        }
        
        return nil
    }
    
    private func getBus(forIndexPath indexPath: IndexPath) -> Bus? {
        if indexPath.section == 0 {
            return nil
        }
        
        return showsStarredBuses && indexPath.section == 1 ? BusManager.shared.starredBuses[indexPath.row] : BusManager.shared.buses[indexPath.row]
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let bus = getBus(forIndexPath: indexPath) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "BusCell")!
            cell.textLabel?.text = bus.name ?? bus._id
            return cell
        } else {
            return tableView.dequeueReusableCell(withIdentifier: "HeaderCell")!
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section > 0 {
            performSegue(withIdentifier: "showMapStep", sender: tableView)
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showMapStep" {
            let bus = getBus(forIndexPath: tableView.indexPathForSelectedRow!)!
            (segue.destination as! CustomStopsMapViewController).bus = bus
        }
    }

}
