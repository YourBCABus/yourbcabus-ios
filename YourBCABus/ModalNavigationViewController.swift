//
//  ModalNavigationViewController.swift
//  YourBCABus
//
//  Created by Anthony Li on 11/4/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import UIKit
import MapKit

class ModalNavigationViewController: MapViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    @IBOutlet weak var mapOutlet: MKMapView!
    @IBOutlet weak var visualEffectView: UIVisualEffectView!
    @IBOutlet weak var etaLabel: UILabel!
    @IBOutlet weak var destinationText: UILabel!
    @IBOutlet weak var exitButton: UIButton!
    @IBOutlet weak var pageControl: UIPageControl!
    
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
            if let route = route {
                if let eta = route.eta {
                    etaLabel.text = formatter.string(from: eta)
                } else {
                    etaLabel.text = "ETA Unavailable"
                }
                destinationText.text = "to \(route.destination.name ?? "Unknown Destination")"
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
        pageViewController.setViewControllers([UIViewController()], direction: .forward, animated: false, completion: nil)
        
        pageControl.currentPage = 0
        pageControl.numberOfPages = 100
        
        // Do any additional setup after loading the view.
        configureView()
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        return nil
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        
    }
    
    @IBAction func exit(sender: UIButton?) {
        dismiss(animated: true, completion: {})
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
