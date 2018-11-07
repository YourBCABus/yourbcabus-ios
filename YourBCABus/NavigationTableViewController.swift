//
//  NavigationTableViewController.swift
//  YourBCABus
//
//  Created by Anthony Li on 11/4/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import UIKit
import MapKit

class NavigationTableViewController: UITableViewController, UITextFieldDelegate {
    
    private var searchTimer: Timer?
    private weak var searchField: UITextField?
    var debounceInterval = 0.5
    var searchCenter = MapViewControllerPoints.standard.school
    var searchSpan = MKCoordinateSpan(latitudeDelta: 2, longitudeDelta: 2)
    var defaultsKey = "recentRoutes"
    
    var isSearching = false {
        didSet {
            if isSearching {
                places = []
            } else {
                places = recents
            }
            tableView.reloadSections(IndexSet(integer: 1), with: .none)
        }
    }
    var places = [MKMapItem]()
    var recents = [MKMapItem]()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
        
        do {
            recents = try ((UserDefaults.standard.array(forKey: defaultsKey) as? [Data]) ?? []).map({ (data) throws in
                return try NSKeyedUnarchiver.unarchivedObject(ofClass: MKMapItem.self, from: data)
            }).filter({$0 != nil}).map({$0!})
            places = recents
            tableView.reloadData()
        } catch {}
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return nil
        } else {
            return isSearching ? "Search Results" : "Suggested"
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? 1 : places.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "InputCell", for: indexPath) as! TextFieldTableViewCell
            cell.textField?.delegate = self
            searchField = cell.textField
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "DestinationCell", for: indexPath)
            let place = places[indexPath.row]
            cell.textLabel?.text = place.name
            cell.detailTextLabel?.text = [place.placemark.locality, place.placemark.administrativeArea].filter({$0 != nil}).map({$0!}).joined(separator: ", ")
            return cell
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let timer = searchTimer {
            timer.invalidate()
        }
        
        searchTimer = Timer.scheduledTimer(timeInterval: debounceInterval, target: self, selector: #selector(updateSearch), userInfo: nil, repeats: false)
        
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        updateSearchFrom(nil)
        
        return true
    }
    
    @objc func updateSearch() {
        searchTimer = nil
        updateSearchFrom(searchField?.text?.trimmingCharacters(in: CharacterSet.whitespaces))
    }
    
    func updateSearchFrom(_ from: String?) {
        if let text = from {
            if text.count > 0 {
                isSearching = true
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
                
                let query = MKLocalSearch.Request()
                query.naturalLanguageQuery = text
                query.region = MKCoordinateRegion(center: searchCenter, span: searchSpan)
                
                let localSearch = MKLocalSearch(request: query)
                localSearch.start { [weak self] (response, error) in
                    guard self?.isSearching == true else {
                        return
                    }
                    
                    guard error == nil else {
                        return
                    }
                    
                    if let places = response?.mapItems {
                        self?.places = places
                    } else {
                        self?.places = []
                    }
                    
                    self?.tableView.reloadSections(IndexSet(integer: 1), with: .none)
                    
                    DispatchQueue.main.async {
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    }
                }
                
                return
            }
        }
        
        isSearching = false
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            performSegue(withIdentifier: "showRoutes", sender: tableView)
        }
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let routes = segue.destination as? RoutesTableViewController else {
            return
        }
        
        guard let selected = (sender as? UITableView)?.indexPathForSelectedRow else {
            return
        }
        
        if selected.section == 1 {
            let place = places[selected.row]
            routes.destination = place
            
            let overage = places.count - 20
            if overage > 0 {
                recents.removeLast(overage)
            }
            
            recents.removeAll(where: { item in
                return item == place
            })
            
            recents.insert(place, at: 0)
            
            do {
                try UserDefaults.standard.setValue(recents.map({ item in
                    return try NSKeyedArchiver.archivedData(withRootObject: item, requiringSecureCoding: true)
                }), forKey: defaultsKey)
            } catch {}
        }
    }
    
}
