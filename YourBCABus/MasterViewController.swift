//
//  MasterViewController.swift
//  YourBCABus
//
//  Created by Anthony Li on 10/19/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import UIKit
import YourBCABus_Embedded

enum MasterTableViewSection {
    case alerts
    case maps
    case starred
    case buses
}

class MasterViewController: UITableViewController, UISearchControllerDelegate, UISearchResultsUpdating {
    
    var schoolId = Constants.schoolId

    var detailViewController: DetailViewController? = nil
    
    var sections: [MasterTableViewSection] = [.maps, .buses]
    
    var resultsViewController: SearchResultsViewController!
    var searchController: UISearchController!
        
    var refreshInterval: TimeInterval = 15
    private var refreshTimer: Timer?
    
    private var notificationTokens = [NotificationToken]()
    
    static let didAskToSetUpNotificationsDefaultsKey = "didAskToSetUpBusArrivalNotifications"
    static let didOpenNotificationsAlertDefaultsKey = "didOpenNotificationsAlert"
    
    @available(*, deprecated)
    static let currentDestinationDefaultsKey = Constants.currentDestinationDefaultsKey
    
    static let dismissedAlertsDefaultsKey = "dismissedAlerts"
    static let dismissedAlertsDidChange = Notification.Name("YBBDismissedAlertsDidChange")
    
    var alerts = [Alert]()
    
    func updateAlerts(_ theAlerts: [Alert]) {
        let oldLength = alerts.count
        let dismissedAlerts = UserDefaults.standard.dictionary(forKey: MasterViewController.dismissedAlertsDefaultsKey) ?? [:]
        alerts = theAlerts.filter { dismissedAlerts[$0._id] == nil }
        if oldLength > 0 && alerts.count > 0 {
            tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        } else {
            tableView.reloadData()
        }
    }
    
    func reloadBuses(cachingMode: APICachingMode, completion: ((Bool) -> Void)? = nil) {
        APIService.shared.getBuses(schoolId: schoolId, cachingMode: cachingMode) { result in
            if result.ok {
                let temp = result.result.sorted()
                
                DispatchQueue.main.async {
                    BusManager.shared.buses = temp
                    BusManager.shared.busesUpdated()
                    self.tableView.reloadData()
                    completion?(true)
                }
            } else {
                print(result.error!)
                
                DispatchQueue.main.async {
                    completion?(false)
                }
            }
        }
        
        APIService.shared.getAlerts(schoolId: schoolId) { result in
            if result.ok {
                DispatchQueue.main.async {
                    self.updateAlerts(result.result)
                }
            } else {
                print(result.error!)
            }
        }
    }
    
    func askToSetUpNotifications() {
        performSegue(withIdentifier: "askToSetUpNotifications", sender: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
        
        refreshControl?.tintColor = UIColor.white
        
        notificationTokens.append(NotificationCenter.default.observe(name: Notification.Name(BusManager.NotificationName.starredBusesChange.rawValue), object: nil, queue: nil, using: { [weak self] notification in
            let index = self?.sections.firstIndex(of: .starred)
            if index != nil && BusManager.shared.starredBuses.count > 0 {
                self?.tableView.reloadSections(IndexSet(integer: index!), with: .fade)
            } else {
                self?.tableView.reloadData()
            }
            
            if let busId = notification.userInfo?[BusManager.NotificationUserInfoKey.busID] as? String {
                if self?.view.window != nil && (BusManager.shared.starredBuses.contains(where: {$0._id == busId}) && !UserDefaults.standard.bool(forKey: MasterViewController.didAskToSetUpNotificationsDefaultsKey)) {
                    self?.askToSetUpNotifications()
                }
            }
        }))
        
        notificationTokens.append(NotificationCenter.default.observe(name: MasterViewController.dismissedAlertsDidChange, object: nil, queue: nil, using: { [weak self] notification in
            if let self = self {
                self.updateAlerts(self.alerts)
            }
        }))
        
        resultsViewController = SearchResultsViewController()
        resultsViewController.tableView.delegate = self
        
        searchController = UISearchController(searchResultsController: resultsViewController)
        searchController.searchResultsUpdater = self
        searchController.searchBar.autocapitalizationType = .none
        searchController.delegate = self
        searchController.searchBar.tintColor = UIColor.white
        searchController.searchBar.barStyle = .black
        
        // TODO: better
        UILabel.appearance(whenContainedInInstancesOf: [UISearchBar.self]).textColor = UIColor.white.withAlphaComponent(0.5)
        
        if #available(iOS 13.0, *) {
            searchController.searchBar.searchTextField.leftView?.tintColor = .white
            searchController.searchBar.barTintColor = .white
            searchController.searchBar.searchTextField.tintColor = .white
        }
        
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        
        definesPresentationContext = true
        
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true, block: { [weak self] timer in
            // if self?.view.window != nil {
                self?.reloadBuses(cachingMode: .forceFetch)
            // }
        })
        
        reloadBuses(cachingMode: .both)
    }

    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController?.isCollapsed == true
        super.viewWillAppear(animated)
    }
    
    @IBAction func refreshControlPulled(sender: UIRefreshControl?) {
        reloadBuses(cachingMode: .forceFetch) { (success) in
            sender?.endRefreshing()
        }
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
            controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
            controller.navigationItem.leftItemsSupplementBackButton = true
            controller.navigationItem.largeTitleDisplayMode = .never

            if let indexPath = searchController?.isActive == true ? resultsViewController.tableView.indexPathForSelectedRow : tableView.indexPathForSelectedRow {
                if searchController?.isActive == true {
                    controller.detailItem = BusManager.shared.filteredBuses[indexPath.row]
                } else {
                    switch sections[indexPath.section] {
                    case .starred:
                        controller.detailItem = BusManager.shared.starredBuses[indexPath.row]
                    case .buses:
                        controller.detailItem = BusManager.shared.buses[indexPath.row]
                    default:
                        controller.detailItem = nil
                        controller.navigationItem.title = nil
                    }
                }
                
                controller.navigationItem.title = controller.detailItem?.description
            } else {
                controller.detailItem = nil
                controller.navigationItem.title = nil
            }
        } else if segue.identifier == "showMap" {
            let controller = (segue.destination as! UINavigationController).topViewController!
            controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
            controller.navigationItem.leftItemsSupplementBackButton = true
            controller.navigationItem.largeTitleDisplayMode = .never
        } else if segue.identifier == "showChangeDestination" {
            (segue.destination as! UINavigationController).topViewController!.navigationItem.largeTitleDisplayMode = .never
        } else if segue.identifier == "showAlert" {
            let alert = alerts[(sender as! UITableView).indexPathForSelectedRow!.row]
            
            let controller = (segue.destination as! UINavigationController).topViewController as! AlertViewController
            controller.alert = alert
            
            controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
            controller.navigationItem.leftItemsSupplementBackButton = true
            controller.navigationItem.largeTitleDisplayMode = .never
        }
    }

    // MARK: - Table View
    
    func refreshSections() {
        if alerts.count > 0 {
            if !sections.contains(.alerts) {
                sections.insert(.alerts, at: 0)
            }
        } else {
            if let index = sections.firstIndex(of: .alerts) {
                sections.remove(at: index)
            }
        }
        
        if BusManager.shared.starredBuses.count > 0 {
            if !sections.contains(.starred) {
                sections.insert(.starred, at: sections.firstIndex(of: .buses)!)
            }
        } else {
            if let index = sections.firstIndex(of: .starred) {
                sections.remove(at: index)
            }
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        refreshSections()
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch sections[section] {
        case .maps:
            return "Maps"
        case .starred:
            return "Starred Buses"
        case .buses:
            return "Buses"
        default:
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
        case .alerts:
            return alerts.count
        case .maps:
            return 1
        case .starred:
            return BusManager.shared.starredBuses.count
        case .buses:
            return BusManager.shared.buses.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch sections[indexPath.section] {
        case .alerts:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TextCell", for: indexPath)
            let alert = alerts[indexPath.row]
            
            let attributedString = NSMutableAttributedString()
            if !alert.type.name.isEmpty {
                attributedString.append(NSAttributedString(string: "\(alert.type.name): ", attributes: [
                    .font: UIFont.systemFont(ofSize: UIFont.labelFontSize, weight: .bold),
                    .foregroundColor: alert.type.color.color
                ]))
            }
            
            attributedString.append(NSAttributedString(string: alert.title))
            
            cell.textLabel?.attributedText = attributedString
            return cell
        case .maps:
            let cell = tableView.dequeueReusableCell(withIdentifier: "TextCell", for: indexPath)
            
            cell.textLabel?.text = "BCA Parking Lot Map"
            return cell
        case .starred:
            let cell = tableView.dequeueReusableCell(withIdentifier: "BusCell", for: indexPath) as! BusTableViewCell
            
            cell.bus = BusManager.shared.starredBuses[indexPath.row]
            return cell
        case .buses:
            let cell = tableView.dequeueReusableCell(withIdentifier: "BusCell", for: indexPath) as! BusTableViewCell
            
            cell.bus = BusManager.shared.buses[indexPath.row]
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView !== self.tableView {
            return 60
        } else {
            switch sections[indexPath.section] {
            case .alerts, .maps:
                return 44
            case .starred, .buses:
                return 60
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if searchController?.isActive == true {
            performSegue(withIdentifier: "showDetail", sender: tableView)
        } else {
            switch sections[indexPath.section] {
            case .alerts:
                performSegue(withIdentifier: "showAlert", sender: tableView)
            case .maps:
                performSegue(withIdentifier: "showMap", sender: tableView)
            case .starred, .buses:
                performSegue(withIdentifier: "showDetail", sender: tableView)
            }
        }
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }
    
    /*func didPresentSearchController(_ searchController: UISearchController) {
        if let button = searchController.searchBar.subviews.first?.subviews.last as? UIButton {
           button.tintColor = UIColor.white
        }
    }*/

    func updateSearchResults(for searchController: UISearchController) {
        BusManager.shared.updateFilteredBuses(term: searchController.searchBar.text!.trimmingCharacters(in: CharacterSet.whitespaces))
        (searchController.searchResultsController as? UITableViewController)?.tableView.reloadData()
    }
    
    deinit {
        refreshTimer?.invalidate()
    }
}
