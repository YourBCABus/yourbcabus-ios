//
//  MapViewController.swift
//  YourBCABus
//
//  Created by Anthony Li on 10/24/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import UIKit
import MapKit

struct MapViewControllerPoints {
    static var standard = MapViewControllerPoints()
    
    var au = CLLocationCoordinate2D(latitude: 40.9017077, longitude: -74.0346963)
    var auString = "AU"
    
    var aCoords = [
        CLLocationCoordinate2D(latitude: 40.9002284, longitude: -74.0339698),
        CLLocationCoordinate2D(latitude: 40.9002946, longitude: -74.033927),
        CLLocationCoordinate2D(latitude: 40.9003482, longitude: -74.033895),
        CLLocationCoordinate2D(latitude: 40.900407, longitude: -74.0338587),
        CLLocationCoordinate2D(latitude: 40.9004668, longitude: -74.0338225),
        CLLocationCoordinate2D(latitude: 40.9005171, longitude: -74.0337916),
        CLLocationCoordinate2D(latitude: 40.9005664, longitude: -74.0337546)
    ]
    var aDLat: CLLocationDegrees = -0.000015
    var aDLong: CLLocationDegrees = 0.00003
    var aCharset: [Character] = ["A", "B", "C", "D", "E"]
    
    var bCoords: [CLLocationCoordinate2D] = [
        CLLocationCoordinate2D(latitude: 40.9006914, longitude: -74.0336413),
        CLLocationCoordinate2D(latitude: 40.9006722, longitude: -74.033542),
        CLLocationCoordinate2D(latitude: 40.900659, longitude: -74.0334482),
        CLLocationCoordinate2D(latitude: 40.9006388, longitude: -74.0333529),
        CLLocationCoordinate2D(latitude: 40.9006093, longitude: -74.0332416),
        CLLocationCoordinate2D(latitude: 40.9005677, longitude: -74.0331397),
        CLLocationCoordinate2D(latitude: 40.900516, longitude: -74.0330405),
        CLLocationCoordinate2D(latitude: 40.9004643, longitude: -74.0329425),
        CLLocationCoordinate2D(latitude: 40.9004044, longitude: -74.0328514),
        CLLocationCoordinate2D(latitude: 40.90034, longitude: -74.0327756)
    ]
    var bDLat: CLLocationDegrees = -0.00004
    var bDLong: CLLocationDegrees = 0
    var bCharset: [Character] = ["F", "G", "H", "I", "J", "K"]
    
    func pointForLocation(_ location: String) -> CLLocationCoordinate2D? {
        if location == auString {
            return au
        } else if location.count >= 2 {
            guard let id = Int(location[location.index(location.startIndex, offsetBy: 1)...]) else {
                return nil
            }
            
            let first = location.first!
            if let index = aCharset.firstIndex(of: first) {
                guard id <= aCoords.count else {
                    return nil
                }
                
                var coord = aCoords[id - 1]
                let multiplier = aCharset.count - index - 1
                
                coord.latitude += aDLat * CLLocationDegrees(multiplier)
                coord.longitude += aDLong * CLLocationDegrees(multiplier)
                
                return coord
            }
            
            if let index = bCharset.firstIndex(of: first) {
                guard id <= bCoords.count else {
                    return nil
                }
                
                var coord = bCoords[id - 1]
                coord.latitude += bDLat * CLLocationDegrees(index)
                coord.longitude += bDLong * CLLocationDegrees(index)
                
                return coord
            }
        }
        
        return nil
    }
}

class BusAnnotation: MKPointAnnotation {
    enum BusType {
        case standard
        case starred
        case home
    }
    
    var bus: Bus?
    var type = BusType.standard
}

class MapViewController: UIViewController, MKMapViewDelegate {
    
    var points = MapViewControllerPoints.standard
    
    var mapView: MKMapView! {
        return view as? MKMapView
    }
    
    var schoolRect =
        MKMapRect(origin: MKMapPoint(CLLocationCoordinate2D(latitude: 40.900623, longitude: -74.033684)), size: MKMapSize(width: 400, height: 100))
    
    var busImage = UIImage(named: "Annotation - Bus")!
    var starredImage = UIImage(named: "Annotation - Bus Starred")!
    
    var detailBus: String? {
        didSet {
            mapView.annotations.forEach { annotation in
                if let a = annotation as? BusAnnotation {
                    let view = mapView.view(for: a)
                    if let detail = detailBus {
                        view?.alpha = a.bus?._id == detail ? 1 : 0.2
                        view?.canShowCallout = a.bus?._id == detail
                        view?.rightCalloutAccessoryView = nil
                    } else {
                        view?.alpha = 1
                        view?.canShowCallout = true
                        view?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
                    }
                }
            }
        }
    }
    
    @objc func reloadAnnotations(notification: Notification? = nil) {
        mapView.addAnnotations(BusManager.shared.buses.map({ (bus) in
            guard let loc = bus.location else {
                return nil
            }
            
            guard let coord = points.pointForLocation(loc) else {
                return nil
            }
            
            let a = BusAnnotation()
            a.coordinate = coord
            a.title = bus.description
            a.subtitle = bus.location!
            a.bus = bus
            a.type = BusManager.shared.isStarred(bus: bus._id) ? BusAnnotation.BusType.starred : BusAnnotation.BusType.standard
            mapView.addAnnotation(a)
            
            return a
        }).filter({ (annotation) in
            return annotation != nil
        }).map({ (annotation) -> MKAnnotation in
            return annotation!
        }))
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        // TODO: Dynamic coordinates
        mapView.setVisibleMapRect(schoolRect, animated: false)
        mapView.mapType = .hybridFlyover
        mapView.delegate = self
        mapView.register(MKAnnotationView.self, forAnnotationViewWithReuseIdentifier: "BusView")
        
        /* for i in "ABCDEFGHIJK" {
            for j in 1...10 {
                if let coord = points.pointForLocation("\(i)\(j)") {
                    let a = MKPointAnnotation()
                    a.coordinate = coord
                    a.title = "\(i)\(j)"
                    mapView.addAnnotation(a)
                }
            }
        } */
        
        NotificationCenter.default.addObserver(self, selector: #selector(reloadAnnotations(notification:)), name: Notification.Name(BusManager.NotificationName.busesChange.rawValue), object: nil)
        
        reloadAnnotations()
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if mapView.camera.altitude < 1500 && mapView.visibleMapRect.intersects(schoolRect) {
            if mapView.mapType != .hybridFlyover {
                mapView.mapType = .hybridFlyover
            }
        } else {
            if mapView.mapType != .mutedStandard {
                mapView.mapType = .mutedStandard
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        switch annotation {
        case let busAnnotation as BusAnnotation:
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: "BusView", for: annotation)
            switch busAnnotation.type {
            case .starred:
                view.image = starredImage
            default:
                view.image = busImage
            }
            
            if let detail = detailBus {
                view.alpha = busAnnotation.bus?._id == detail ? 1 : 0.2
                view.canShowCallout = false
                view.rightCalloutAccessoryView = nil
            } else {
                view.alpha = 1
                view.canShowCallout = true
                view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            }
            
            return view
        default:
            return nil
        }
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        switch view.annotation {
        case let annotation as BusAnnotation:
            if storyboard != nil {
                if annotation.bus != nil {
                    performSegue(withIdentifier: "mapToDetail", sender: annotation)
                }
            }
        default:
            break
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "mapToDetail" {
            let destination = segue.destination as! DetailViewController
            let bus = (sender as! BusAnnotation).bus!
            destination.detailItem = bus
            destination.navigationItem.title = bus.description
        }
    }
    
}
