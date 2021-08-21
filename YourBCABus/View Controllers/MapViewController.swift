//
//  MapViewController.swift
//  YourBCABus
//
//  Created by Anthony Li on 10/24/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import UIKit
import MapKit

class BusAnnotation: MKPointAnnotation {
    enum BusType {
        case standard
        case starred
    }
    
    var bus: BusModel {
        didSet {
            updateContent()
        }
    }
    var type = BusType.standard
    
    init(_ bus: BusModel) {
        self.bus = bus
        super.init()
        updateContent()
    }
    
    func updateContent() {
        title = bus.name ?? "(unnamed bus)"
        subtitle = bus.boardingArea!
    }
}

class StopAnnotation: MKPointAnnotation {
    var stop: StopModel {
        didSet {
            updateContent()
        }
    }
    
    init(_ stop: StopModel) {
        self.stop = stop
        super.init()
        updateContent()
    }
    
    func updateContent() {
        coordinate = CLLocationCoordinate2D(stop.stopLocation!)
        title = stop.name
    }
}

class MapViewController: UIViewController, MKMapViewDelegate {
    static let useFlyoverMapDefaultsKey = "mapViewControllerUseFlyoverMap"
        
    var mapView: MKMapView!
    weak var delegate: MapViewControllerDelegate?
        
    var busImage = UIImage(named: "Annotation - Bus")!
    var starredImage = UIImage(named: "Annotation - Bus Starred")!
    
    var schoolLocation: CLLocationCoordinate2D?
    var mappingData: GetBusesQuery.Data.School.MappingDatum?
    var buses = [BusModel]()
    var stops = [StopModel]()
    var isStarred = Set<String>()
    var detailBus: String?
    
    var schoolRect: MKMapRect {
        if let mappingData = mappingData {
            return MKMapRect(a: MKMapPoint(CLLocationCoordinate2D(mappingData.boundingBoxA)), b: MKMapPoint(CLLocationCoordinate2D(mappingData.boundingBoxB)))
        } else {
            return MKMapRect()
        }
    }
    
    func reframeMap() {
        let stopsToDisplay = stops.filter { $0.stopLocation != nil }
        if stopsToDisplay.isEmpty {
            mapView.setVisibleMapRect(schoolRect, animated: false)
        } else {
            let latitudes = stopsToDisplay.map { $0.stopLocation!.lat }
            let longitudes = stopsToDisplay.map { $0.stopLocation!.long }
            let a = MKMapPoint(CLLocationCoordinate2D(latitude: latitudes.min()!, longitude: longitudes.min()!))
            let b = MKMapPoint(CLLocationCoordinate2D(latitude: latitudes.max()!, longitude: longitudes.max()!))
            mapView.setVisibleMapRect(MKMapRect(a: a, b: b), animated: false)
        }
        if reloadsMapTypeOnRegionChange {
            reloadMapType()
        } else {
            mapView.mapType = schoolAreaMapType
        }
    }
    
    func reloadBuses() {
        let now = Date()
        let boardingAreas = [String: CLLocationCoordinate2D]((mappingData?.boardingAreas ?? []).map { ($0.name, CLLocationCoordinate2D($0.location)) }, uniquingKeysWith: { (_, last) in
            last
        })
        mapView.removeAnnotations(mapView.annotations.filter {$0 is BusAnnotation})
        mapView.addAnnotations(buses.compactMap { bus in
            guard let area = bus.getBoardingArea(at: now) else {
                return nil
            }
            
            guard let coord = boardingAreas[area] else {
                return nil
            }
            
            let a = BusAnnotation(bus)
            a.coordinate = coord
            a.type = isStarred.contains(bus.id) ? BusAnnotation.BusType.starred : BusAnnotation.BusType.standard
            mapView.addAnnotation(a)
            
            return a
        })
    }
    
    func reloadStops() {
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations.filter { $0 is StopAnnotation })
        
        let stopsToDisplay = stops.filter { $0.stopLocation != nil }
        
        if !stops.isEmpty {
            var coords = schoolLocation.map { [$0] } ?? []
            coords.append(contentsOf: stopsToDisplay.map { stop in
                CLLocationCoordinate2D(stop.stopLocation!)
            })
            let overlay = MKPolyline(coordinates: coords, count: coords.count)
            mapView.addOverlay(overlay)
        }
        
        mapView.addAnnotations(stopsToDisplay.map { stop in
            StopAnnotation(stop)
        })
    }
    
    func focus(on coordinate: CLLocationCoordinate2D) {
        mapView.setRegion(MKCoordinateRegion(center: coordinate, latitudinalMeters: 500, longitudinalMeters: 500), animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
    }
    
    func setupView() {
        if mapView == nil {
            mapView = view as? MKMapView
        }
        
        if UserDefaults.standard.bool(forKey: MapViewController.useFlyoverMapDefaultsKey) {
            schoolAreaMapType = .hybridFlyover
        }

        // Do any additional setup after loading the view.
        mapView.showsUserLocation = true
        mapView.delegate = self
        mapView.register(MKAnnotationView.self, forAnnotationViewWithReuseIdentifier: "BusView")
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: "StopView")
        
        reframeMap()
        reloadBuses()
        reloadStops()
    }
    
    var schoolAreaMapType = MKMapType.hybrid
    var schoolAreaMapTypeMaxAltitude: CLLocationDistance = 1500
    var standardMapType = MKMapType.mutedStandard
    
    func reloadMapType() {
        if mapView.camera.altitude < schoolAreaMapTypeMaxAltitude && mapView.visibleMapRect.intersects(schoolRect) {
            if mapView.mapType != schoolAreaMapType {
                mapView.mapType = schoolAreaMapType
            }
        } else {
            if mapView.mapType != standardMapType {
                mapView.mapType = standardMapType
            }
        }
    }
    
    @IBInspectable var reloadsMapTypeOnRegionChange = false
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if reloadsMapTypeOnRegionChange {
            reloadMapType()
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
                view.alpha = busAnnotation.bus.id == detail ? 1 : 0.2
                view.canShowCallout = false
                view.rightCalloutAccessoryView = nil
            } else {
                view.alpha = 1
                view.canShowCallout = true
                view.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            }
            
            return view
        case _ as StopAnnotation:
            return mapView.dequeueReusableAnnotationView(withIdentifier: "StopView", for: annotation)
        default:
            return nil
        }
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        switch view.annotation {
        case let annotation as BusAnnotation:
            delegate?.busSelected(id: annotation.bus.id)
        default:
            break
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = UIColor(named: "Accent")!
        renderer.lineWidth = 3
        return renderer
    }
}

protocol MapViewControllerDelegate: AnyObject {
    func busSelected(id: String)
}
