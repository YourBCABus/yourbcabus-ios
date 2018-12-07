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
    
    private enum Section {
        case customStops
        case nearestStops
        case walking
    }
    private var sections = [Section]()
    
    var destination: MKMapItem? {
        didSet {
            configureView(oldDestination: oldValue)
        }
    }
    
    var isLoading = false {
        didSet {
            UIApplication.shared.isNetworkActivityIndicatorVisible = isLoading
        }
    }
    
    var schoolId = "5bca51e785aa2627e14db459"
    
    var routes = [Route]()
    var nearestStopRoutes: [Route] {
        return routes.filter({route in
            return (route.fetchStatus == .fetched || route.fetchStatus == .errored) && route.stop?.is_custom == false
        }).sorted(by: { (a, b) in
            if a.eta == nil && b.eta == nil {
                return false
            } else if a.eta == nil {
                return false
            } else if b.eta == nil {
                return true
            } else {
                return a.eta! < b.eta!
            }
        })
    }
    var customStopRoutes: [Route] {
        return routes.filter({route in
            return (route.fetchStatus == .fetched || route.fetchStatus == .errored) && route.stop?.is_custom == true
        }).sorted(by: { (a, b) in
            if a.eta == nil && b.eta == nil {
                return false
            } else if a.eta == nil {
                return false
            } else if b.eta == nil {
                return true
            } else {
                return a.eta! < b.eta!
            }
        })
    }
    var walkingRoute: Route?
    
    var maxDistance = 3220
    var formatter = DateFormatter()
    var distanceFormatter = MKDistanceFormatter()
    
    func refreshActivityIndicator() {
        if walkingRoute?.fetchStatus != .fetching && !routes.contains(where: { $0.fetchStatus == Route.FetchStatus.fetching }) {
            isLoading = false
        } else {
            isLoading = true
        }
    }
    
    func configureView(oldDestination: MKMapItem? = nil) {
        if oldDestination != destination {
            routes = []
            
            if let dest = destination {
                self.walkingRoute = Route(destination: self.destination!, stop: nil, schoolId: self.schoolId)
                self.walkingRoute!.fetchData({ [weak self] (ok, error, route) in
                    if let self = self {
                        DispatchQueue.main.async {
                            self.tableView.reloadData()
                            self.refreshActivityIndicator()
                        }
                    }
                })
                
                isLoading = true
                
                APIService.shared.getStops(schoolId: schoolId, near: Coordinate(from: dest.placemark.coordinate), distance: maxDistance) { result in
                    if result.ok {
                        DispatchQueue.main.async {
                            self.routes = result.result.map { stop in
                                return Route(destination: dest, stop: stop, schoolId: self.schoolId)
                            }
                            self.routes.forEach { $0.fetchData { [weak self] (ok, error, route) in
                                if let self = self {
                                    DispatchQueue.main.async {
                                        self.tableView.reloadData()
                                        self.refreshActivityIndicator()
                                    }
                                }
                                
                                if let e = error {
                                    print(e)
                                }
                                } }
                            self.tableView.reloadData()
                            UIApplication.shared.isNetworkActivityIndicatorVisible = true
                        }
                    }
                }
            }
            
            tableView.reloadData()
        }
    }
    
    var loadingFooterView: UIView?
    var normalFooterView: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        
        navigationItem.largeTitleDisplayMode = .never
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        configureView(oldDestination: destination)
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        sections = []
        if nearestStopRoutes.count > 0 {
            sections.append(.nearestStops)
        }
        sections.append(contentsOf: [.walking])
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
        case .customStops:
            return 0
        case .nearestStops:
            return nearestStopRoutes.count
        case .walking:
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch sections[section] {
        case .nearestStops:
            return "Nearest Stops"
        case .walking:
            return "Walking"
        default:
            return nil
        }
    }
    
    func getRoute(for indexPath: IndexPath) -> Route? {
        switch sections[indexPath.section] {
        case .nearestStops:
            return nearestStopRoutes[indexPath.row]
        case .walking:
            return walkingRoute
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RouteCell", for: indexPath) as! RouteTableViewCell
        
        cell.selectionStyle = .default
        cell.accessoryType = .disclosureIndicator
        let route = getRoute(for: indexPath)!
        
        if route.fetchStatus == .fetched {
            cell.selectionStyle = .default
            cell.accessoryType = .disclosureIndicator
        } else {
            cell.selectionStyle = .none
            cell.accessoryType = .none
            
            if route.fetchStatus == .errored {
                if route.stop == nil {
                    cell.stopLabel?.text = "Could not find a route"
                }
                cell.etaLabel?.text = "Error"
                cell.etaLabel?.textColor = UIColor.red
                return cell
            }
        }
        
        if route.stop != nil {
            cell.busLabel?.text = route.bus?.name ?? "No bus"
            cell.stopLabel?.text = route.description
        } else {
            cell.busLabel?.text = "Walking"
            if let distance = route.walkingDistance {
                cell.stopLabel?.text = distanceFormatter.string(fromDistance: distance)
            } else if route.fetchStatus == .errored {
                cell.stopLabel?.text = "Could not find a route"
                cell.selectionStyle = .none
                cell.accessoryType = .none
            } else {
                cell.stopLabel?.text = "Loading..."
            }
        }
        if let eta = route.eta {
            cell.etaLabel?.text = formatter.string(from: eta)
            cell.etaLabel?.textColor = UIColor(named: "Primary Dark")!
        } else {
            cell.etaLabel?.text = "Loading..."
            cell.etaLabel?.textColor = UIColor.lightGray
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let route = getRoute(for: indexPath)!
        if route.fetchStatus == .fetched {
            performSegue(withIdentifier: "startNavigation", sender: tableView)
        }
    }
    
    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if section == sections.count - 1 {
            return isLoading ? loadingFooterView : normalFooterView
        } else {
            return nil
        }
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "startNavigation" {
            let route = getRoute(for: tableView.indexPathForSelectedRow!)!
            let controller = (segue.destination as? UINavigationController)?.topViewController as? ModalNavigationViewController
            controller?.route = route
        }
    }
    
    override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
        coder.encode(destination, forKey: "destination")
    }
    
    override func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
        destination = coder.decodeObject(forKey: "destination") as? MKMapItem
    }
    
}
