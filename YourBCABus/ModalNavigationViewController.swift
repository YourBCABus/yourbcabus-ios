//
//  ModalNavigationViewController.swift
//  YourBCABus
//
//  Created by Anthony Li on 11/4/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import UIKit
import MapKit

private class DestinationAnnotation: MKPointAnnotation {}
private class WalkOverlay: MKPolyline {}

class ModalNavigationViewController: MapViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    @IBOutlet weak var mapOutlet: MKMapView!
    @IBOutlet weak var visualEffectView: UIVisualEffectView!
    @IBOutlet weak var etaLabel: UILabel!
    @IBOutlet weak var destinationText: UILabel!
    @IBOutlet weak var exitButton: UIButton!
    @IBOutlet weak var pageControl: UIPageControl!
    
    var viewControllers = [UIViewController]()
    
    private var formatter = DateFormatter()
    
    var route: Route? {
        didSet {
            configureView()
        }
    }
    
    var pageViewController: UIPageViewController! {
        return children.first(where: {$0 is UIPageViewController}) as? UIPageViewController
    }
    
    func configureView() {
        if viewIfLoaded != nil {
            detailBus = route?.bus?._id ?? MapViewController.noDetailBus
            
            if let route = route {
                if let eta = route.eta {
                    etaLabel.text = formatter.string(from: eta)
                } else {
                    etaLabel.text = "ETA Unavailable"
                }
                destinationText.text = "to \(route.destination.name ?? "Unknown Destination")"
                
                let controllers = route.steps.map({ step -> UIViewController? in
                    switch step {
                    case .boarding:
                        return storyboard?.instantiateViewController(withIdentifier: "boarding")
                    case .riding:
                        return storyboard?.instantiateViewController(withIdentifier: "riding")
                    case .walking:
                        return storyboard?.instantiateViewController(withIdentifier: "walking")
                    default:
                        return storyboard?.instantiateViewController(withIdentifier: "And it's family after genus")
                    }
                })
                
                viewControllers = controllers.map({ controller in
                    let stepController = (controller as? RouteStepViewController) ?? RouteStepViewController()
                    stepController.route = route
                    return stepController
                })
                
                if let stop = route.stop {
                    if let stops = route.stops {
                        mapPoints = [stops.map {BusMapPoint(coordinate: CLLocationCoordinate2D(from: $0.location), title: $0.name ?? "", bus: nil, stopId: $0._id)}]
                    }
                    mapPoints![0].append(BusMapPoint(coordinate: CLLocationCoordinate2D(from: stop.location), title: stop.name ?? "", bus: nil, stopId: stop._id))
                } else {
                    mapPoints = nil
                }
                
                reloadStops()
            } else {
                viewControllers = []
                mapPoints = nil
                reloadStops()
            }
            
            if let controller = viewControllers.first {
                pageViewController.setViewControllers([controller], direction: .forward, animated: false, completion: nil)
                
                pageControl.currentPage = 0
                pageControl.numberOfPages = viewControllers.count
                pageControl.isHidden = false
                if let region = (controller as? RouteStepViewController)?.getMapRegion(for: self) {
                    setRegion(to: region)
                }
            } else {
                pageViewController.setViewControllers(nil, direction: .forward, animated: false, completion: nil)
                pageControl.isHidden = true
                setRegion(to: MKCoordinateRegion(schoolRect))
            }
        }
    }

    override func viewDidLoad() {
        mapView = mapOutlet
        super.viewDidLoad()
        
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        
        visualEffectView.layer.cornerRadius = 10
        visualEffectView.layer.masksToBounds = true
        
        let layer = CALayer()
        layer.shadowColor = UIColor.lightGray.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 0)
        layer.shadowOpacity = 0.4
        layer.shadowRadius = 4
        layer.shadowPath = UIBezierPath(roundedRect: visualEffectView.frame, cornerRadius: 10).cgPath
        
        /*let mask = CALayer()
        mask.frame = visualEffectView.frame.insetBy(dx: -20, dy: -20)
        mask.cornerRadius = 10
        mask.backgroundColor = UIColor.clear.cgColor
        mask.borderColor = UIColor.black.cgColor
        mask.borderWidth = 20
        layer.mask = mask*/
        
        view?.layer.insertSublayer(layer, below: visualEffectView.layer)
        
        exitButton.layer.cornerRadius = 16
        
        pageViewController.dataSource = self
        pageViewController.delegate = self
        
        mapView.register(MKAnnotationView.self, forAnnotationViewWithReuseIdentifier: "MidpointView")
        mapView.register(MKAnnotationView.self, forAnnotationViewWithReuseIdentifier: "OriginView")
        mapView.register(MKPinAnnotationView.self, forAnnotationViewWithReuseIdentifier: "DestinationView")
        
        // Do any additional setup after loading the view.
        configureView()
    }
    
    override func reloadStops() {
        super.reloadStops()
        
        if let route = route {
            if route.steps.contains(.walking) {
                if let walk = route.walkingRoute {
                    mapView.addOverlay(WalkOverlay(points: walk.polyline.points(), count: walk.polyline.pointCount))
                }
                
                let annotation = DestinationAnnotation()
                annotation.coordinate = route.destination.placemark.coordinate
                annotation.title = route.destination.name
                mapView.addAnnotation(annotation)
            }
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if let index = viewControllers.firstIndex(of: viewController) {
            if index > 0 {
                return viewControllers[index - 1]
            }
        }
        
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        if let index = viewControllers.firstIndex(of: viewController) {
            if index < viewControllers.count - 1 {
                return viewControllers[index + 1]
            }
        }
        
        return nil
    }
    
    private var pendingIndex: Int?
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        if pendingIndex == nil {
            if let controller = pendingViewControllers.first {
                if let index = viewControllers.firstIndex(of: controller) {
                    pendingIndex = index
                }
            }
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if let index = pendingIndex {
            pageControl.currentPage = index
            pendingIndex = nil
            
            if let region = (viewControllers[index] as? RouteStepViewController)?.getMapRegion(for: self) {
                setRegion(to: region)
            }
        }
    }
    
    func setRegion(to region: MKCoordinateRegion) {
        let padding: UIEdgeInsets
        
        if traitCollection.verticalSizeClass == .compact {
            padding = UIEdgeInsets(top: view.safeAreaInsets.top, left: view.safeAreaInsets.left, bottom: view.safeAreaInsets.bottom, right: visualEffectView.frame.width + view.safeAreaInsets.right)
        } else {
            padding = UIEdgeInsets(top: view.safeAreaInsets.top, left: view.safeAreaInsets.left, bottom: visualEffectView.frame.height + view.safeAreaInsets.bottom + 80, right: view.safeAreaInsets.right)
        }
        
        let latitudeDelta = region.span.latitudeDelta / 2
        let longitudeDelta = region.span.longitudeDelta / 2
        
        let a = MKMapPoint(CLLocationCoordinate2D(latitude: region.center.latitude - latitudeDelta, longitude: region.center.longitude - longitudeDelta))
        let b = MKMapPoint(CLLocationCoordinate2D(latitude: region.center.latitude + latitudeDelta, longitude: region.center.longitude + longitudeDelta))
        
        mapView.setVisibleMapRect(MKMapRect(a: a, b: b), edgePadding: padding, animated: true)
    }
    
    @IBAction func exit(sender: UIButton?) {
        dismiss(animated: true, completion: {})
    }
    
    lazy var midpointImage: UIImage? = {
        let lineWidth: CGFloat = 4
        let size = CGSize(width: 16, height: 16)
        let bounds = CGRect(origin: CGPoint.zero, size: size)
        
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        let context = UIGraphicsGetCurrentContext()
        
        context?.setFillColor(UIColor.white.cgColor)
        context?.setStrokeColor(UIColor(named: "Accent")!.cgColor)
        context?.setLineWidth(lineWidth)
        
        let ellipse = bounds.insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
        context?.fillEllipse(in: ellipse)
        context?.strokeEllipse(in: ellipse)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }()
    
    lazy var destinationImage: UIImage? = {
        let lineWidth: CGFloat = 4
        let size = CGSize(width: 20, height: 20)
        let bounds = CGRect(origin: CGPoint.zero, size: size)
        
        UIGraphicsBeginImageContextWithOptions(size, false, UIScreen.main.scale)
        let context = UIGraphicsGetCurrentContext()
        
        context?.setFillColor(UIColor.white.cgColor)
        context?.setStrokeColor(UIColor.darkGray.cgColor)
        context?.setLineWidth(lineWidth)
        
        let ellipse = bounds.insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
        context?.fillEllipse(in: ellipse)
        context?.strokeEllipse(in: ellipse)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }()
    
    override func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        switch annotation {
        case let theAnnotation as StopAnnotation:
            if theAnnotation.stopId == nil {
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: "OriginView", for: annotation)
                view.isHidden = true
                return view
            } else if theAnnotation.stopId == route?.stop?._id {
                return mapView.dequeueReusableAnnotationView(withIdentifier: "StopView", for: annotation)
            } else {
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: "MidpointView", for: annotation)
                view.canShowCallout = true
                if view.image == nil {
                    view.image = midpointImage
                }
                return view
            }
        case _ as DestinationAnnotation:
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: "DestinationView", for: annotation)
            view.canShowCallout = true
            return view
        default:
            return super.mapView(mapView, viewFor: annotation)
        }
    }
    
    override func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if overlay is WalkOverlay {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIColor.darkGray
            renderer.lineDashPattern = [20, 10]
            renderer.lineCap = .butt
            renderer.lineWidth = 10
            return renderer
        } else {
            return super.mapView(mapView, rendererFor: overlay)
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
