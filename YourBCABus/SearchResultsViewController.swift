//
//  SearchResultsViewController.swift
//  YourBCABus
//
//  Created by Anthony Li on 10/23/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import UIKit

class SearchResultsViewController: UITableViewController {
    
    static let nibName = "BusTableViewCell"

    override func viewDidLoad() {
        tableView.register(UINib(nibName: SearchResultsViewController.nibName, bundle: nil), forCellReuseIdentifier: "BusCell")
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Search Results"
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return BusManager.shared.filteredBuses.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BusCell", for: indexPath) as! BusTableViewCell
        
        cell.bus = BusManager.shared.filteredBuses[indexPath.row]
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

}
