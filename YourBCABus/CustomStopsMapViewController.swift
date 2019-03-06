//
//  CustomStopsMapViewController.swift
//  YourBCABus
//
//  Created by Anthony Li on 12/8/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import UIKit
import MapKit
import YourBCABus_Embedded

class CustomStopsMapViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var visualEffectView: UIVisualEffectView?
    @IBOutlet weak var placeNameLabel: UILabel?
    @IBOutlet weak var continueButton: UIButton?
    
    private var stopAnnotation: MKAnnotation?
    private var geocoder = CLGeocoder()
    
    var initialCoordinateSpan = MKCoordinateRegion(center: MapViewControllerPoints.standard.school, latitudinalMeters: 50000, longitudinalMeters: 50000)
    
    var bus: Bus?
    var currentCoordinate: CLLocationCoordinate2D?
    var placemark: CLPlacemark?

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.setRegion(initialCoordinateSpan, animated: false)
        mapView.register(MKPinAnnotationView.self, forAnnotationViewWithReuseIdentifier: "StopAnnotation")
        mapView.delegate = self
        
        continueButton?.layer.cornerRadius = 8
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func tapGestureRecognized(sender: UIGestureRecognizer?) {
        if let recognizer = sender {
            guard recognizer.state == .began else {
                return
            }
            
            let point = recognizer.location(in: view)
            if mapView.frame.contains(point) {
                guard visualEffectView?.frame.contains(point) != true else { return }
                
                let coordinate = mapView.convert(point, toCoordinateFrom: view)
                
                if stopAnnotation != nil {
                    mapView.removeAnnotation(stopAnnotation!)
                }
                
                let annotation = MKPointAnnotation()
                annotation.coordinate = coordinate
                mapView.addAnnotation(annotation)
                stopAnnotation = annotation
                
                let feedbackGenerator = UIImpactFeedbackGenerator()
                feedbackGenerator.impactOccurred()
                
                placeNameLabel?.text = "Loading..."
                continueButton?.isEnabled = false
                
                currentCoordinate = coordinate
                
                geocoder.reverseGeocodeLocation(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude), completionHandler: { (result, error) in
                    if self.currentCoordinate == coordinate {
                        DispatchQueue.main.async {
                            if let placemark = result?.first {
                                self.placemark = placemark
                                self.placeNameLabel?.text = placemark.name
                                self.continueButton?.isEnabled = true
                            } else {
                                self.placeNameLabel?.text = "Please try again"
                            }
                        }
                    }
                })
            }
        }
    }
        
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation === stopAnnotation {
            if let view = mapView.dequeueReusableAnnotationView(withIdentifier: "StopAnnotation") as? MKPinAnnotationView {
                view.pinTintColor = MKPinAnnotationView.purplePinColor()
                view.animatesDrop = true
                return view
            }
        }
        
        return nil
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? CustomStopsTimeViewController {
            destination.bus = bus
            destination.placemark = placemark
        }
    }

}
