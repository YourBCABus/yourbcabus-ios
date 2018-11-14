//
//  DetailViewController.swift
//  YourBCABus
//
//  Created by Anthony Li on 10/19/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import UIKit
import CoreLocation

class DetailViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var formatter = DateFormatter()
    @IBOutlet weak var stopTableView: UITableView!
    
    var detailItem: Bus? {
        didSet {
            stops = []
            if let bus = detailItem {
                APIService.shared.getStops(schoolId: bus.school_id, busId: bus._id, cachingMode: .both) { result in
                    if result.ok {
                        if self.detailItem?._id == bus._id {
                            let temp = result.result.sorted()
                            let mapPoints = temp.map { stop in
                                return BusMapPoint(coordinate: CLLocationCoordinate2D(from: stop.location), title: stop.description, bus: nil, stopId: stop._id)
                            }
                            
                            DispatchQueue.main.async {
                                self.stops = temp
                                self.stopTableView.reloadData()
                                let mapController = self.children.first(where: { controller in
                                    return controller is MapViewController
                                }) as? MapViewController
                                mapController?.mapPoints = [mapPoints]
                                
                                let now = Date()
                                var calendar = Calendar(identifier: .gregorian)
                                calendar.timeZone = TimeZone(identifier: "America/New_York")!
                                if self.detailItem?.location == nil || (calendar.component(.hour, from: now) != 16 || calendar.component(.minute, from: now) >= 40) {
                                    mapController?.showMapPoints()
                                }
                            }
                        }
                    } else {
                        print(result.error!)
                    }
                }
            }
            
            configureView()
        }
    }
    
    var stops = [Stop]()

    func configureView() {
        // Update the user interface for the detail item.
        if let bus = detailItem {
            navigationItem.title = bus.description
            let mapController = children.first(where: { controller in
                return controller is MapViewController
            }) as? MapViewController
            mapController?.detailBus = bus._id
            mapController?.mapPoints = [[]]
            mapController?.reloadStops()
        }
        
        stopTableView?.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        
        // Do any additional setup after loading the view, typically from a nib.
        stopTableView.dataSource = self
        stopTableView.delegate = self
        
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        
        configureView()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return nil
        } else {
            return "Stops"
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return stops.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "StatusCell") as! BusStatusTableViewCell
            cell.statusLabel.text = detailItem?.getStatus()
            cell.secondaryLabel.text = detailItem == nil ? nil : "\(stops.count) stop\(stops.count == 1 ? "" : "s")"
            cell.locationView.location = detailItem?.location
            cell.locationView.available = detailItem?.available == true
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "StopCell")!
            let stop = stops[indexPath.row]
            cell.textLabel?.text = stop.description
            cell.detailTextLabel?.text = stop.arrives == nil ? nil : formatter.string(from: stop.arrives!)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
}

