//
//  RoutesTableViewController.swift
//  YourBCABus
//
//  Created by Anthony Li on 11/4/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import UIKit
import MapKit

class RoutesTableViewController: UITableViewController {
    
    var destination: MKMapItem? {
        didSet {
            configureView()
        }
    }
    
    var schoolId = "5bca51e785aa2627e14db459"
    
    var routes = [Route]()
    var maxDistance = 3220
    var formatter = DateFormatter()
    
    func configureView() {
        routes = []
        
        if let dest = destination {
            APIService.shared.getStops(schoolId: schoolId, near: Coordinate(from: dest.placemark.coordinate), distance: maxDistance) { result in
                if result.ok {
                    DispatchQueue.main.async {
                        self.routes = result.result.map { stop in
                            return Route(destination: dest, stop: stop, schoolId: self.schoolId)
                        }
                        self.routes.append(Route(destination: dest, stop: nil, schoolId: self.schoolId))
                        self.routes.forEach { $0.fetchData { [weak self] (ok, error, route) in
                            if let self = self {
                                DispatchQueue.main.async {
                                    self.tableView.reloadData()
                                }
                                
                                if let eta = route.eta {
                                    print("\(route.description) arrives at \(self.formatter.string(from: eta))")
                                }
                            }
                        } }
                        self.tableView.reloadData()
                    }
                }
            }
        }
        
        tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        formatter.dateStyle = .none
        formatter.timeStyle = .short

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        configureView()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return routes.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Routes"
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RouteCell", for: indexPath)
        let route = routes[indexPath.row]
        if route.stop != nil {
            cell.textLabel?.text = route.bus?.name ?? "No bus"
            cell.detailTextLabel?.text = route.description
        } else {
            cell.textLabel?.text = route.description
            cell.detailTextLabel?.text = nil
        }
        if let eta = route.eta {
            // cell.detailTextLabel?.text = formatter.string(from: eta)
        } else {
            // cell.detailTextLabel?.text = nil
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "startNavigation", sender: tableView)
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
