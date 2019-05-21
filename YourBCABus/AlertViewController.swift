//
//  AlertViewController.swift
//  YourBCABus
//
//  Created by Anthony Li on 5/20/19.
//  Copyright © 2019 YourBCABus. All rights reserved.
//

import UIKit
import WebKit

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
        webView?.isHidden = true
        webView?.loadHTMLString(htmlString, baseURL: nil)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let js = alertsScript {
            webView.evaluateJavaScript(js, completionHandler: { _, _ in
                webView.isHidden = false
            })
        }
    }
    
    var htmlString = "" {
        didSet {
            if isViewLoaded {
                configureView()
            }
        }
    }

}
