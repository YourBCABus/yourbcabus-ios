//
//  TodayViewController.swift
//  YourBCABus Today
//
//  Created by Anthony Li on 3/8/19.
//  Copyright © 2019 YourBCABus. All rights reserved.
//

import UIKit
import NotificationCenter
import YourBCABus_Embedded

class TodayViewController: UIViewController, NCWidgetProviding {
    
    @IBOutlet weak var openAppButton: UIButton?
    
    var routeOverviewViewController: RouteOverviewViewController?
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        extensionContext?.widgetLargestAvailableDisplayMode = .expanded
        
        routeOverviewViewController = RouteOverviewViewController(nibName: "RouteOverviewView", bundle: Bundle(for: RouteOverviewViewController.self))
        if let vc = routeOverviewViewController {
            vc.view.frame = view.bounds
            vc.view.isHidden = true
            view.addSubview(vc.view)
            let views = ["view": vc.view!]
            var constraints = [NSLayoutConstraint]()
            constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[view]-0-|", options: [], metrics: nil, views: views))
            constraints.append(contentsOf: NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[view]-0-|", options: [], metrics: nil, views: views))
            view.addConstraints(constraints)
        }
        
        widgetPerformUpdate(completionHandler: { result in
            // Do nothing.
        })
    }
    
    func widgetActiveDisplayModeDidChange(_ activeDisplayMode: NCWidgetDisplayMode, withMaximumSize maxSize: CGSize) {
        if activeDisplayMode == .expanded {
            preferredContentSize = CGSize(width: maxSize.width, height: 220)
            routeOverviewViewController?.isCompact = false
        } else {
            preferredContentSize = maxSize
            routeOverviewViewController?.isCompact = true
        }
    }
        
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        if let data = UserDefaults(suiteName: Constants.groupId)?.data(forKey: Constants.currentDestinationDefaultsKey) {
            do {
                let route = try PropertyListDecoder().decode(Route.self, from: data)
                openAppButton?.isHidden = true
                routeOverviewViewController?.route = route
                routeOverviewViewController?.view.isHidden = false
                route.fetchData { (_, _, _) in
                    DispatchQueue.main.async {
                        self.routeOverviewViewController?.configureView()
                    }
                    if route.fetchStatus == .fetched || route.fetchStatus == .errored {
                        completionHandler(NCUpdateResult.newData)
                    }
                    if let data = try? PropertyListEncoder().encode(route) {
                        UserDefaults(suiteName: Constants.groupId)?.set(data, forKey: Constants.currentDestinationDefaultsKey)
                    }
                }
            } catch {
                openAppButton?.isHidden = false
                routeOverviewViewController?.view.isHidden = true
                completionHandler(NCUpdateResult.failed)
            }
        } else {
            openAppButton?.isHidden = false
            routeOverviewViewController?.view.isHidden = true
            completionHandler(NCUpdateResult.newData)
        }
        
        routeOverviewViewController?.isTransparent = true
    }
    
    @IBAction func openApp(sender: UIButton?) {
        if let url = URL(string: "yourbcabus://app/navigation/destinations") {
            extensionContext?.open(url, completionHandler: nil)
        }
    }
    
}
