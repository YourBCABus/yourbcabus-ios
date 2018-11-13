//
//  RouteStepViewController.swift
//  YourBCABus
//
//  Created by Anthony Li on 11/12/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import UIKit
import MapKit

class RouteStepViewController: UIViewController {
    var route: Route!
    var isComplete: Bool {
        return false
    }
}

class BoardingStepViewController: RouteStepViewController {
    @IBOutlet weak var busNameLabel: UILabel?
    @IBOutlet weak var descriptionLabel: UILabel?
    @IBOutlet weak var locationView: BusLocationView?
    
    private var notificationTokens = [NotificationToken]()
    
    func configureView(with bus: Bus) {
        busNameLabel?.text = bus.name
        descriptionLabel?.text = bus.getStatus()
        locationView?.available = bus.available
        locationView?.location = bus.location
    }
    
    override func viewDidLoad() {
        configureView(with: route.bus!)
        notificationTokens.append(NotificationCenter.default.observe(name: Notification.Name(BusManager.NotificationName.busesChange.rawValue), object: nil, queue: nil, using: { [unowned self] notification in
            if let bus = BusManager.shared.buses.first(where: { bus in
                return bus._id == self.route.bus?._id
            }) {
                self.configureView(with: bus)
            }
        }))
    }
}

class RidingStepScrimView: UIView {
    override func draw(_ rect: CGRect) {
        let clear = UIColor(named: "Background")!.withAlphaComponent(0)
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = rect
        gradientLayer.colors = [UIColor(named: "Background")!.cgColor, clear.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0.6)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.render(in: UIGraphicsGetCurrentContext()!)
    }
}

class RidingStepSummaryTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var arrivalLabel: UILabel!
    
    var timeFormatter = { () -> DateFormatter in
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    func configureView(with route: Route) {
        if let stops = route.stops {
            titleLabel.text = "Ride \(stops.count) stops to"
        } else {
            titleLabel.text = "Ride bus to"
        }
        
        nameLabel.text = route.stop?.name
        
        if let arrives = route.stop?.arrives {
            arrivalLabel.text = "Arrives at stop \(timeFormatter.string(from: arrives))"
        } else {
            arrivalLabel.text = nil
        }
    }
}

class RidingStepViewController: RouteStepViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SummaryCell") as! RidingStepSummaryTableViewCell
        cell.configureView(with: route)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 185
    }
}

class WalkingStepViewController: RouteStepViewController {
    @IBOutlet weak var continueInMapsButton: UIButton?
    @IBOutlet weak var timeLabel: UILabel?
    @IBOutlet weak var distanceLabel: UILabel?
    
    override var isComplete: Bool {
        return true
    }
    
    var timeFormatter = { () -> DateComponentsFormatter in
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .short
        formatter.allowedUnits = [.hour, .minute]
        return formatter
    }()
    var distanceFormatter = MKDistanceFormatter()
    
    override func viewDidLoad() {
        continueInMapsButton?.isEnabled = route?.walkingRoute != nil
        continueInMapsButton?.layer.cornerRadius = 16
        
        if let directions = route?.walkingRoute {
            timeLabel?.text = timeFormatter.string(from: directions.expectedTravelTime)
            distanceLabel?.text = distanceFormatter.string(fromDistance: directions.distance)
        }
    }
    
    @IBAction func continueInMaps(sender: UIView?) {
        var origin: MKMapItem?
        if let stop = route?.stop {
            origin = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(from: stop.location)))
            origin!.name = stop.name ?? origin!.name
        } else if let school = route?.school {
            origin = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(from: school.location)))
            origin!.name = school.name
        }
        
        if let origin = origin {
            if let destination = route?.destination {
                MKMapItem.openMaps(with: [origin, destination], launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeWalking])
            }
        }
    }
}
