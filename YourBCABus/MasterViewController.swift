//
//  MasterViewController.swift
//  YourBCABus
//
//  Created by Anthony Li on 10/19/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import UIKit

enum MasterTableViewSection {
    case buses
}

class MasterViewController: UITableViewController {

    var detailViewController: DetailViewController? = nil
    var buses = [Bus]()
    
    var sections: [MasterTableViewSection] = [.buses]
    
    func reloadBuses() {
        APIService.shared.getBuses(schoolId: "5bca51e785aa2627e14db459") { result in
            print(result)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
        
        reloadBuses()
    }

    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        /*if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                
            }
        }*/
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch sections[section] {
        case .buses:
            return "Buses"
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
        case .buses:
            return buses.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch sections[indexPath.section] {
        case .buses:
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            
            let bus = buses[indexPath.row]
            cell.textLabel!.text = bus.name == nil ? "No Name" : bus.name!
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }


}

