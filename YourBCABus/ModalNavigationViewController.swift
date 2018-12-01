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
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var statusBarVisualEffectView: UIVisualEffectView!
    
    var onDoneBlock: (() -> Void)?
    
    var viewControllers = [UIViewController]()
    
    private var formatter = DateFormatter()
    private var restoredPage: Int?
    
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
            
            if viewControllers.count > 0 {
                let controller = viewControllers[restoredPage ?? 0]
                pageViewController.setViewControllers([controller], direction: .forward, animated: false, completion: nil)
                
                pageControl.currentPage = restoredPage ?? 0
                restoredPage = nil
                pageControl.numberOfPages = viewControllers.count
                pageControl.isHidden = false
                if let type = (controller as? RouteStepViewController)?.getMapType(for: self) {
                    mapView.mapType = type
                }
                if let region = (controller as? RouteStepViewController)?.getMapRegion(for: self) {
                    setRegion(to: region)
                }
            } else {
                pageControl.isHidden = true
                setRegion(to: MKCoordinateRegion(schoolRect))
            }
        }
    }
    
    var shadowLayer = CALayer()

    override func viewDidLoad() {
        mapView = mapOutlet
        reloadsMapTypeOnRegionChange = false
        super.viewDidLoad()
        
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        
        visualEffectView.layer.cornerRadius = 10
        visualEffectView.layer.masksToBounds = true
        
        shadowLayer.shadowColor = UIColor.lightGray.cgColor
        shadowLayer.shadowOffset = CGSize(width: 0, height: 0)
        shadowLayer.shadowOpacity = 0.4
        shadowLayer.shadowRadius = 4
        shadowLayer.shadowPath = UIBezierPath(roundedRect: visualEffectView.frame, cornerRadius: 10).cgPath
        
        view?.layer.insertSublayer(shadowLayer, below: visualEffectView.layer)
        
        exitButton.layer.cornerRadius = 16
        
        let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: [:])
        addChild(pageViewController)
        pageViewController.view.frame = containerView.frame
        containerView.addSubview(pageViewController.view)
        pageViewController.dataSource = self
        pageViewController.delegate = self
        
        mapView.register(MKAnnotationView.self, forAnnotationViewWithReuseIdentifier: "MidpointView")
        mapView.register(MKAnnotationView.self, forAnnotationViewWithReuseIdentifier: "OriginView")
        mapView.register(MKPinAnnotationView.self, forAnnotationViewWithReuseIdentifier: "DestinationView")
        
        pageControl.addTarget(self, action: #selector(pageControlDidChangeValue(sender:)), for: .valueChanged)
        
        // Do any additional setup after loading the view.
        configureView()
    }
    
    override func reloadStops() {
        super.reloadStops()
        
        if let route = route {
            if route.steps.contains(.walking) {
                if let walk = route.walkingPolyline {
                    mapView.addOverlay(WalkOverlay(points: walk.points(), count: walk.pointCount))
                }
                
                let annotation = DestinationAnnotation()
                annotation.coordinate = route.destination.placemark.coordinate
                annotation.title = route.destination.name
                mapView.addAnnotation(annotation)
            }
        }
    }
    
    @objc func pageControlDidChangeValue(sender: UIPageControl?) {
        if let page = sender?.currentPage {
            if (0..<viewControllers.count).contains(page) {
                var direction = UIPageViewController.NavigationDirection.forward
                if let current = pageViewController.viewControllers?.first {
                    if let index = viewControllers.firstIndex(of: current) {
                        if index > page {
                            direction = .reverse
                        }
                    }
                }
                
                pageViewController.setViewControllers([viewControllers[page]], direction: direction, animated: true, completion: nil)
                
                if let region = (viewControllers[page] as? RouteStepViewController)?.getMapRegion(for: self) {
                    setRegion(to: region)
                }
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
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            if let index = viewControllers.firstIndex(of: pageViewController.viewControllers![0]) {
                pageControl.currentPage = index
                
                if let type = (viewControllers[index] as? RouteStepViewController)?.getMapType(for: self) {
                    mapView.mapType = type
                }
                
                if let region = (viewControllers[index] as? RouteStepViewController)?.getMapRegion(for: self) {
                    setRegion(to: region)
                }
            }
        }
    }
    
    func setRegion(to region: MKCoordinateRegion) {
        let padding: UIEdgeInsets
        
        if traitCollection.verticalSizeClass == .compact {
            padding = UIEdgeInsets(top: view.safeAreaInsets.top + 30, left: view.safeAreaInsets.left + 30, bottom: view.safeAreaInsets.bottom + 30, right: visualEffectView.frame.width + view.safeAreaInsets.right + 30)
        } else {
            padding = UIEdgeInsets(top: view.safeAreaInsets.top + 30, left: view.safeAreaInsets.left + 30, bottom: visualEffectView.frame.height + view.safeAreaInsets.bottom + 80, right: view.safeAreaInsets.right + 30)
        }
        
        let latitudeDelta = region.span.latitudeDelta / 2
        let longitudeDelta = region.span.longitudeDelta / 2
        
        let a = MKMapPoint(CLLocationCoordinate2D(latitude: region.center.latitude - latitudeDelta, longitude: region.center.longitude - longitudeDelta))
        let b = MKMapPoint(CLLocationCoordinate2D(latitude: region.center.latitude + latitudeDelta, longitude: region.center.longitude + longitudeDelta))
        
        mapView.setVisibleMapRect(MKMapRect(a: a, b: b), edgePadding: padding, animated: true)
    }
    
    @IBAction func exit(sender: UIButton?) {
        onDoneBlock?()
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
    
    override func encodeRestorableState(with coder: NSCoder) {
        super.encodeRestorableState(with: coder)
        
        if let route = route {
            do {
                coder.encode(try PropertyListEncoder().encode(route), forKey: "route")
            } catch {}
        }
        
        if let current = pageViewController.viewControllers?.first {
            if let index = viewControllers.firstIndex(of: current) {
                coder.encode(index, forKey: "currentPage")
            }
        }
    }
    
    override func decodeRestorableState(with coder: NSCoder) {
        super.decodeRestorableState(with: coder)
        
        if coder.containsValue(forKey: "route") {
            do {
                route = try PropertyListDecoder().decode(Route.self, from: coder.decodeObject(forKey: "route") as! Data)
            } catch {}
        }
        
        if coder.containsValue(forKey: "currentPage") {
            restoredPage = coder.decodeInteger(forKey: "currentPage")
            if restoredPage != nil && (0..<viewControllers.count).contains(restoredPage!) {
                pageViewController.setViewControllers([viewControllers[restoredPage!]], direction: .forward, animated: false, completion: nil)
                pageControl.currentPage = restoredPage!
                
                if let region = (viewControllers[restoredPage!] as? RouteStepViewController)?.getMapRegion(for: self) {
                    setRegion(to: region)
                }
                
                restoredPage = nil
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        shadowLayer.shadowPath = UIBezierPath(roundedRect: visualEffectView.frame, cornerRadius: 10).cgPath
        statusBarVisualEffectView.frame = UIApplication.shared.statusBarFrame
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
