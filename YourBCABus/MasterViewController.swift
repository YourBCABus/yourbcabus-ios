//
//  MasterViewController.swift
//  YourBCABus
//
//  Created by Anthony Li on 10/19/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import UIKit

enum MasterTableViewSection {
    case starred
    case buses
}

class MasterViewController: UITableViewController, UISearchControllerDelegate, UISearchResultsUpdating {
    
    var schoolId = "5bca51e785aa2627e14db459"

    var detailViewController: DetailViewController? = nil
    
    var sections: [MasterTableViewSection] = [.buses]
    
    var resultsViewController: SearchResultsViewController!
    var searchController: UISearchController!
    
    private var starredBusesChangeListener: BusManagerStarListener?
    
    func reloadBuses(cachingMode: APICachingMode, completion: ((Bool) -> Void)? = nil) {
        APIService.shared.getBuses(schoolId: schoolId, cachingMode: cachingMode) { result in
            if result.ok {
                let temp = result.result.sorted()
                
                DispatchQueue.main.async {
                    BusManager.shared.buses = temp
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
    }
    
    func removeStarredBusesChangeListener() {
        if let listener = starredBusesChangeListener {
            BusManager.shared.removeStarredBusesChangeListener(listener)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
        
        reloadBuses(cachingMode: .both)
        refreshControl?.tintColor = UIColor.white
        
        removeStarredBusesChangeListener()
        starredBusesChangeListener = BusManagerStarListener(listener: { [unowned self] in
            let index = self.sections.firstIndex(of: .starred)
            if index != nil && BusManager.shared.starredBuses.count > 0 {
                self.tableView.reloadSections(IndexSet(integer: index!), with: .fade)
            } else {
                self.tableView.reloadData()
            }
        })
        BusManager.shared.addStarredBusesChangeListener(starredBusesChangeListener!)
        
        resultsViewController = SearchResultsViewController()
        resultsViewController.tableView.delegate = self
        
        searchController = UISearchController(searchResultsController: resultsViewController)
        searchController.searchResultsUpdater = self
        searchController.searchBar.autocapitalizationType = .none
        searchController.delegate = self
        searchController.searchBar.tintColor = UIColor.white
        
        if #available(iOS 11.0, *) {
            // For iOS 11 and later, place the search bar in the navigation bar.
            navigationItem.searchController = searchController
            navigationItem.hidesSearchBarWhenScrolling = false
        } else {
            // For iOS 10 and earlier, place the search controller's search bar in the table view's header.
            tableView.tableHeaderView = searchController.searchBar
        }
        
        definesPresentationContext = true
    }

    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
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
                    }
                }
                
                controller.navigationItem.title = controller.detailItem?.description
            } else {
                controller.detailItem = nil
                controller.navigationItem.title = nil
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        sections = BusManager.shared.starredBuses.count > 0 ? [.starred, .buses] : [.buses]
        return sections.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch sections[section] {
        case .starred:
            return "Starred Buses"
        case .buses:
            return "Buses"
        }
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
        case .starred:
            return BusManager.shared.starredBuses.count
        case .buses:
            return BusManager.shared.buses.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch sections[indexPath.section] {
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
        switch sections[indexPath.section] {
        case .starred, .buses:
            return 60
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if searchController?.isActive == true {
            performSegue(withIdentifier: "showDetail", sender: tableView)
        } else {
            switch sections[indexPath.section] {
            case .starred, .buses:
                performSegue(withIdentifier: "showDetail", sender: tableView)
            }
        }
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return false
    }
    
    deinit {
        removeStarredBusesChangeListener()
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
}
