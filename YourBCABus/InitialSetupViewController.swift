//
//  InitialSetupViewController.swift
//  YourBCABus
//
//  Created by Anthony Li on 6/15/19.
//  Copyright © 2019 YourBCABus. All rights reserved.
//

import UIKit
import MapKit

class SearchBarInstallationPoint: UIView {}

class InitialSetupViewController: UIViewController, UISearchBarDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar?
    @IBOutlet weak var containerView: UIView!
    
    let resultsController = InitialSetupPlaceResultsViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar?.delegate = self
        
        addChild(resultsController)
        containerView.addSubview(resultsController.view)
        resultsController.view.frame = containerView.bounds
        containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[view]-0-|", metrics: nil, views: ["view": resultsController.view!]))
        containerView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[view]-0-|", metrics: nil, views: ["view": resultsController.view!]))
        
        resultsController.selectListeners.append({ [weak self] mapItem in
            self?.performSegue(withIdentifier: "showNearbyStops", sender: mapItem)
        })
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let delay = 0.5
        
        containerView.isHidden = searchText.isEmpty
        NSObject.cancelPreviousPerformRequests(withTarget: resultsController)
        NSObject.cancelPreviousPerformRequests(withTarget: searchBar, selector: #selector(UISearchBar.resignFirstResponder), object: nil)
        resultsController.perform(#selector(InitialSetupPlaceResultsViewController.update(searchText:)), with: searchText, afterDelay: delay)
        
        if searchText.isEmpty {
            searchBar.perform(#selector(UISearchBar.resignFirstResponder), with: nil, afterDelay: delay)
        }
    }
    
    @IBAction func setUpManually(sender: UIButton?) {
        if let key = BusManager.shared.starredDefaultsKey, UserDefaults.standard.dictionary(forKey: key) != nil {

        } else {
            performSegue(withIdentifier: "showBuses", sender: nil)
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "showNearbyStops":
            let destination = segue.destination as! RoutesTableViewController
            destination.destination = (sender as! MKMapItem)
        default:
            break
        }
    }

}

class InitialSetupPlaceResultsViewController: UITableViewController {
    private let cellIdentifier = "Cell"
    private let subtitleCellIdentifier = "SubtitleCell"
    
    var result: Result<[MKMapItem], Error>?
    var search: MKLocalSearch?
    
    var selectListeners = [(MKMapItem) -> ()]()
    
    @objc func update(searchText: String) {
        result = nil
        tableView.reloadData()
        
        search?.cancel()
        
        if !searchText.isEmpty {
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = searchText
            
            search = MKLocalSearch(request: request)
            search?.start(completionHandler: { [weak self] (response, error) in
                if let self = self {
                    if let response = response {
                        self.result = .success(response.mapItems)
                    } else if let error = error {
                        self.result = .failure(error)
                    }
                    
                    self.search = nil
                    
                    DispatchQueue.main.async {
                        self.tableView.reloadData()
                    }
                }
            })
        }
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
        guard let result = result, case .success(let places) = result else {
            return 1
        }
        
        return places.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let result = result, case .success(let places) = result {
            let cell = tableView.dequeueReusableCell(withIdentifier: subtitleCellIdentifier) ?? UITableViewCell(style: .subtitle, reuseIdentifier: subtitleCellIdentifier)
            cell.accessoryType = .disclosureIndicator
            
            let item = places[indexPath.row]
            cell.textLabel?.text = item.name
            cell.detailTextLabel?.text = [item.placemark.locality, item.placemark.administrativeArea, item.placemark.country].filter { $0 != nil }.map{ $0! }.joined(separator: ", ")
            
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier)!
            cell.selectionStyle = .none
            cell.textLabel?.alpha = 0.5
            
            if let result = result, case .failure(_) = result {
                cell.textLabel?.text = "Error"
            } else {
                cell.textLabel?.text = "Loading..."
            }
            
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let result = result, case .success(let places) = result {
            let place = places[indexPath.row]
            selectListeners.forEach { $0(place) }
        }
    }
    
    deinit {
        search?.cancel()
    }
}
