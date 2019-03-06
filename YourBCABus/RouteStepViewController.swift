//
//  RouteStepViewController.swift
//  YourBCABus
//
//  Created by Anthony Li on 11/12/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import UIKit
import MapKit
import YourBCABus_Embedded

class RouteStepViewController: UIViewController {
    var route: Route!
    var isComplete: Bool {
        return false
    }
    
    func getMapRegion(for: ModalNavigationViewController) -> MKCoordinateRegion? {
        return nil
    }
    
    func getMapType(for controller: ModalNavigationViewController) -> MKMapType? {
        return controller.standardMapType
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
    
    override func getMapRegion(for viewController: ModalNavigationViewController) -> MKCoordinateRegion? {
        return MKCoordinateRegion(center: MapViewControllerPoints.standard.school, latitudinalMeters: 150, longitudinalMeters: 150)
    }
    
    override func getMapType(for controller: ModalNavigationViewController) -> MKMapType? {
        return controller.schoolAreaMapType
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
            if stops.count == 0 {
                titleLabel.text = "Ride 1 stop to"
            } else {
                titleLabel.text = "Ride \(stops.count + 1) stops to"
            }
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

class RidingStepStopTableViewCell: UITableViewCell {
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var arrivalLabel: UILabel?
    
    var timeFormatter = { () -> DateFormatter in
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    func configureView(with stop: Stop) {
        nameLabel.text = stop.name
        if let arrives = stop.arrives {
            arrivalLabel?.text = timeFormatter.string(from: arrives)
        } else {
            arrivalLabel?.text = nil
        }
    }
    
    func configureView(with school: School) {
        nameLabel.text = school.name
        arrivalLabel?.text = nil
    }
}

class RidingStepViewController: RouteStepViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    
    enum Section: Int {
        case summary = 0
        case origin = 1
        case midpoints = 2
        case destination = 3
    }
    
    var sections = [Section.summary]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if route?.stops != nil {
            if route!.school != nil {
                sections.append(.origin)
            }
            sections.append(.midpoints)
            sections.append(.destination)
        }
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.reloadData()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section].rawValue {
        case 2:
            return route.stops!.count
        default:
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch sections[indexPath.section].rawValue {
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "OriginCell") as! RidingStepStopTableViewCell
            cell.configureView(with: route.school!)
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "MidpointCell") as! RidingStepStopTableViewCell
            cell.configureView(with: route.stops![indexPath.row])
            return cell
        case 3:
            let cell = tableView.dequeueReusableCell(withIdentifier: "DestinationCell") as! RidingStepStopTableViewCell
            cell.configureView(with: route.stop!)
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "SummaryCell") as! RidingStepSummaryTableViewCell
            cell.configureView(with: route)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch sections[indexPath.section] {
        case .destination:
            return 76
        case .summary:
            return 185
        default:
            return 36
        }
    }
    
    override func getMapRegion(for controller: ModalNavigationViewController) -> MKCoordinateRegion? {
        return controller.regionForMapPoints(latitudePadding: 0, longitudePadding: 0)
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
        continueInMapsButton?.isEnabled = route?.walkingDistance != nil
        continueInMapsButton?.layer.cornerRadius = 16
        
        if let eta = route?.walkingETA {
            timeLabel?.text = timeFormatter.string(from: eta)
            distanceLabel?.text = distanceFormatter.string(fromDistance: route!.walkingDistance!)
        } else {
            timeLabel?.text = "ETA Unavailable"
            distanceLabel?.text = "Distance unavailable"
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
    
    override func getMapRegion(for: ModalNavigationViewController) -> MKCoordinateRegion? {
        if let boundingMapRect = route?.walkingPolyline?.boundingMapRect {
            return MKCoordinateRegion(boundingMapRect)
        } else {
            return nil
        }
    }
}
