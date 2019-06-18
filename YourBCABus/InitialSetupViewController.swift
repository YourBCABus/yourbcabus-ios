//
//  InitialSetupViewController.swift
//  YourBCABus
//
//  Created by Anthony Li on 6/15/19.
//  Copyright © 2019 YourBCABus. All rights reserved.
//

import UIKit

class SearchBarInstallationPoint: UIView {}

class InitialSetupViewController: UIViewController {
    
    @IBOutlet weak var searchBarInstallationPoint: SearchBarInstallationPoint!
    var searchController: UISearchController!

    override func viewDidLoad() {
        super.viewDidLoad()
                
        let resultsController = InitialSetupPlaceResultsViewController()
        
        searchController = UISearchController(searchResultsController: resultsController)
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchResultsUpdater = resultsController
        searchController.hidesNavigationBarDuringPresentation = false
        
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.searchBarStyle = .minimal
        searchController.searchBar.tintColor = .white
        searchController.searchBar.barTintColor = .white
        
        searchController.searchBar.placeholder = "Address"
        searchController.searchBar.frame = searchBarInstallationPoint.bounds
        
        searchBarInstallationPoint.addSubview(searchController.searchBar)
        searchBarInstallationPoint.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[view]-0-|", metrics: nil, views: ["view": searchController.searchBar]))
        
        definesPresentationContext = true
    }
    
    @IBAction func setUpManually(sender: UIButton?) {
        if let key = BusManager.shared.starredDefaultsKey, UserDefaults.standard.dictionary(forKey: key) != nil {

        } else {
            performSegue(withIdentifier: "showBuses", sender: nil)
        }
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

class InitialSetupPlaceResultsViewController: UITableViewController, UISearchResultsUpdating {
    private let cellIdentifier = "Cell"
    
    func updateSearchResults(for searchController: UISearchController) {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.backgroundColor = .clear
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1000
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)!
        cell.textLabel?.text = "sdf"
        return cell
    }
}
