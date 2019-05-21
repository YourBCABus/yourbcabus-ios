//
//  AlertViewController.swift
//  YourBCABus
//
//  Created by Anthony Li on 5/20/19.
//  Copyright © 2019 YourBCABus. All rights reserved.
//

import UIKit
import WebKit
import YourBCABus_Embedded

class AlertViewController: UIViewController, WKNavigationDelegate {
    
    @IBOutlet weak var webView: WKWebView?
    
    var alertsScript: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        webView?.navigationDelegate = self
        
        if let path = Bundle.main.path(forResource: "alerts-script", ofType: "js") {
            alertsScript = try? String(contentsOfFile: path)
        }

        configureView()
    }
    
    func configureView() {
        navigationItem.title = alert?.title ?? "Travel Advisory"
        webView?.isHidden = true
        webView?.loadHTMLString(alert?.content ?? "", baseURL: nil)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let js = alertsScript {
            webView.evaluateJavaScript(js, completionHandler: { _, _ in
                webView.isHidden = false
            })
        }
    }
    
    var alert: Alert? {
        didSet {
            if isViewLoaded {
                configureView()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let alert = alert {
            if alert.can_dismiss {
                var dismissedAlerts = UserDefaults.standard.dictionary(forKey: MasterViewController.dismissedAlertsDefaultsKey) ?? [:]
                dismissedAlerts[alert._id] = true
                UserDefaults.standard.set(dismissedAlerts, forKey: MasterViewController.dismissedAlertsDefaultsKey)
                NotificationCenter.default.post(name: MasterViewController.dismissedAlertsDidChange, object: nil)
            }
        }
    }

}
