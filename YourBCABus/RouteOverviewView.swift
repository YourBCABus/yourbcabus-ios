//
//  RouteOverviewView.swift
//  YourBCABus
//
//  Created by Anthony Li on 3/2/19.
//  Copyright © 2019 YourBCABus. All rights reserved.
//

import UIKit

class RouteOverviewViewController: UIViewController {
    @IBOutlet weak var destinationLabel: UILabel?
    @IBOutlet weak var busLabel: UILabel?
    @IBOutlet weak var stopLabel: UILabel?
    @IBOutlet weak var statusLabel: UILabel?
    @IBOutlet weak var etaLabel: UILabel?
    @IBOutlet weak var locationView: BusLocationView?
    
    @IBOutlet var detailsButtons: [UIButton]?
    
    var etaFormatter = DateFormatter()
    
    var route: Route? {
        didSet {
            if isViewLoaded {
                configureView()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        etaFormatter.dateStyle = .none
        etaFormatter.timeStyle = .short
        
        let semanticContentAttribute: UISemanticContentAttribute = UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft ? .forceLeftToRight : .forceRightToLeft
        detailsButtons?.forEach { button in
            button.semanticContentAttribute = semanticContentAttribute
            button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -4)
        }
        
        if let layer = statusLabel?.layer {
            layer.cornerRadius = 8
            layer.masksToBounds = true
        }
        
        locationView?.circleColor = UIColor(named: "Accent Light")!
        locationView?.textColor = .black
        
        locationView?.noLocationCircleColor = UIColor(named: "Accent Light")!.withAlphaComponent(0.6)
        locationView?.noLocationTextColor = UIColor.black.withAlphaComponent(0.6)
                
        configureView()
    }
    
    func configureView() {
        guard let route = route else {
            return
        }
        
        if let statusLabel = statusLabel {
            if let status = route.bus?.status {
                statusLabel.isHidden = false
                statusLabel.backgroundColor = status.color
                
                var grayscale: CGFloat = 1.0
                status.color.getWhite(&grayscale, alpha: nil)
                
                if grayscale > 0.65 {
                    statusLabel.textColor = .black
                } else {
                    statusLabel.textColor = .white
                }
                
                statusLabel.text = "   \(status.description)   "
            } else {
                statusLabel.isHidden = true
            }
        }
        
        destinationLabel?.text = route.destination.name ?? "Your Destination"
        if let bus = route.bus {
            busLabel?.text = "via \(bus)"
            locationView?.location = bus.location
            locationView?.available = bus.available
            locationView?.isHidden = false
        } else {
            busLabel?.text = "Walking"
            locationView?.isHidden = true
        }
        if let stop = route.stop {
            stopLabel?.isHidden = false
            stopLabel?.text = stop.name
        } else {
            stopLabel?.isHidden = true
        }
        etaLabel?.text = route.eta == nil ? "Unknown" : etaFormatter.string(from: route.eta!)
    }
    
    @IBAction func moreDetails(sender: Any?) {
        let modalViewController = UIStoryboard(name: "Navigation", bundle: nil).instantiateViewController(withIdentifier: "YBBNavigationModalViewController") as! ModalNavigationViewController
        modalViewController.route = route
        modalViewController.modalPresentationStyle = .fullScreen
        (parent ?? self).present(modalViewController, animated: true, completion: nil)
    }
}
