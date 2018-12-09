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
    var maxCustomStopDistance = 3220 * 1.5
    var formatter = DateFormatter()
    var distanceFormatter = MKDistanceFormatter()
    
    var customStops = [Stop]()
    
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
                            
                            let sortedRoutes = self.customStops.filter({ stop in
                                return dest.placemark.location!.distance(from: CLLocation(latitude: stop.location.latitude, longitude: stop.location.longitude)) < self.maxCustomStopDistance
                            }).sorted(by: { (a, b) in
                                return dest.placemark.location!.distance(from: CLLocation(latitude: a.location.latitude, longitude: a.location.longitude)) < dest.placemark.location!.distance(from: CLLocation(latitude: b.location.latitude, longitude: b.location.longitude))
                            })
                            
                            self.routes.append(contentsOf: sortedRoutes[0..<min(3, sortedRoutes.count)].map({ stop in
                                return Route(destination: dest, stop: stop, schoolId: self.schoolId)
                            }))
                            
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
                        }
                    }
                }
            }
            
            tableView.reloadData()
        }
    }
    
    var loadingFooterView: UIViewController?
    var normalFooterView: UIViewController?
    
    private var notificationToken: NotificationToken?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        
        navigationItem.largeTitleDisplayMode = .never
        
        loadingFooterView = storyboard?.instantiateViewController(withIdentifier: "YBBRoutesLoadingFooterView")
        normalFooterView = storyboard?.instantiateViewController(withIdentifier: "YBBRoutesNormalFooterView")
        
        if let button = normalFooterView?.view.subviews.first(where: {$0 is UIButton}) as? UIButton {
            button.addTarget(self, action: #selector(addCustomStop(sender:)), for: .touchUpInside)
        }
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        customStops = try! Stop.getCustomStops()
        notificationToken = NotificationCenter.default.observe(name: CustomStopsCompletionViewController.finishNotificationName, object: nil, queue: nil, using: { [unowned self] notification in
            self.customStops = try! Stop.getCustomStops()
            
            if let dest = self.destination {
                self.routes.removeAll(where: {$0.stop?.is_custom == true})
                
                let sortedRoutes = self.customStops.filter({ stop in
                    return dest.placemark.location!.distance(from: CLLocation(latitude: stop.location.latitude, longitude: stop.location.longitude)) < self.maxCustomStopDistance
                }).sorted(by: { (a, b) in
                    return dest.placemark.location!.distance(from: CLLocation(latitude: a.location.latitude, longitude: a.location.longitude)) < dest.placemark.location!.distance(from: CLLocation(latitude: b.location.latitude, longitude: b.location.longitude))
                })
                
                let routes = sortedRoutes[0..<min(3, sortedRoutes.count)].map({ stop in
                    return Route(destination: dest, stop: stop, schoolId: self.schoolId)
                })
                
                self.isLoading = true
                
                routes.forEach { $0.fetchData { [weak self] (ok, error, route) in
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
            
                self.routes.append(contentsOf: routes)
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            }
        })
        
        configureView(oldDestination: destination)
    }
    
    @objc func addCustomStop(sender: Any?) {
        performSegue(withIdentifier: "addCustomStop", sender: sender)
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        sections = []
        if customStopRoutes.count > 0 {
            sections.append(.customStops)
        }
        if nearestStopRoutes.count > 0 {
            sections.append(.nearestStops)
        }
        sections.append(contentsOf: [.walking])
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
        case .customStops:
            return customStopRoutes.count
        case .nearestStops:
            return nearestStopRoutes.count
        case .walking:
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch sections[section] {
        case .customStops:
            return "Custom Stops"
        case .nearestStops:
            return "Nearest Stops"
        case .walking:
            return "Walking"
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return sections[section] == .customStops ? "You can manage custom stops in Settings." : nil
    }
    
    func getRoute(for indexPath: IndexPath) -> Route? {
        switch sections[indexPath.section] {
        case .customStops:
            return customStopRoutes[indexPath.row]
        case .nearestStops:
            return nearestStopRoutes[indexPath.row]
        case .walking:
            return walkingRoute
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
            let view = isLoading ? loadingFooterView?.view : normalFooterView?.view
            return view
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section == sections.count - 1 {
            return 200
        } else if sections[section] == .customStops {
            return 30
        } else {
            return 0
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
