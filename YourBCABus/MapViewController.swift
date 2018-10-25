//
//  MapViewController.swift
//  YourBCABus
//
//  Created by Anthony Li on 10/24/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {
    
    var mapView: MKMapView! {
        return view as? MKMapView
    }
    
    var schoolRect =
        MKMapRect(origin: MKMapPoint(CLLocationCoordinate2D(latitude: 40.900623, longitude: -74.033684)), size: MKMapSize(width: 400, height: 100))

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        // TODO: Dynamic coordinates
        mapView.setVisibleMapRect(schoolRect, animated: false)
        mapView.mapType = .hybridFlyover
        mapView.delegate = self
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
    
}
