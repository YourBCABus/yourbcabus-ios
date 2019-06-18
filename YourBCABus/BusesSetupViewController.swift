//
//  BusesSetupViewController.swift
//  YourBCABus
//
//  Created by Anthony Li on 6/15/19.
//  Copyright © 2019 YourBCABus. All rights reserved.
//

import UIKit
import YourBCABus_Embedded

class BusesSetupViewController: UITableViewController {

    enum State {
        case loading
        case success(buses: [Bus])
        case failure(error: Error?)
    }
    
    var state = State.loading {
        didSet {
            DispatchQueue.main.async {
                self.tableView?.reloadData()
            }
        }
    }
    
    fileprivate static let cellIdentifier = "Cell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: BusesSetupViewController.cellIdentifier)
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        APIService.shared.getBuses(schoolId: Constants.schoolId, cachingMode: .forceFetch, { [weak self] result in
            self?.state = result.ok ? .success(buses: result.result.sorted()) : .failure(error: result.error)
            DispatchQueue.main.async {
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
        })
        
        clearsSelectionOnViewWillAppear = true
        definesPresentationContext = true
        
        let resultsController = BusesSetupSearchResultsViewController()
        resultsController.mainViewController = self
        
        let searchController = UISearchController(searchResultsController: resultsController)
        searchController.searchResultsUpdater = resultsController
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.tintColor = UIColor.white

        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch state {
        case .success(let buses):
            return buses.count
        default:
            return 1
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: BusesSetupViewController.cellIdentifier)!
        switch state {
        case .success(let buses):
            let bus = buses[indexPath.row]
            cell.accessoryType = .disclosureIndicator
            cell.textLabel?.alpha = 1
            cell.textLabel?.text = bus.name ?? bus._id
            cell.selectionStyle = .default
        case .loading:
            cell.accessoryType = .none
            cell.textLabel?.alpha = 0.5
            cell.textLabel?.text = "Loading buses..."
            cell.selectionStyle = .none
        case .failure(_):
            cell.accessoryType = .none
            cell.textLabel?.alpha = 0.5
            cell.textLabel?.text = "Failed to load buses"
            cell.selectionStyle = .none
        }
        return cell
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }

}

class BusesSetupSearchResultsViewController: UITableViewController, UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        if let main = mainViewController, case .success(let all) = main.state {
            buses = all.filter { $0.name?.localizedCaseInsensitiveContains(searchController.searchBar.text!.lowercased()) ?? false }
        } else {
            buses = []
        }
    }

    weak var mainViewController: BusesSetupViewController?
    
    private var buses = [Bus]() {
        didSet {
            DispatchQueue.main.async {
                self.tableView?.reloadData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: BusesSetupViewController.cellIdentifier)
        clearsSelectionOnViewWillAppear = true
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return buses.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let bus = buses[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: BusesSetupViewController.cellIdentifier)!
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.alpha = 1
        cell.textLabel?.text = bus.name ?? bus._id
        cell.selectionStyle = .default
        return cell
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
}
