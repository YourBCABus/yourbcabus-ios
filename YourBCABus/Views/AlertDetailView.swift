//
//  AlertDetailView.swift
//  AlertDetailView
//
//  Created by Anthony Li on 8/17/21.
//  Copyright © 2021 YourBCABus. All rights reserved.
//

import SwiftUI
import WebKit
import Apollo

struct AlertDetailView: View {
    var alertID: String
    @State var result: Result<GraphQLResult<GetAlertQuery.Data>, Error>?
    @State var loadCancellable: Apollo.Cancellable?
    
    func loadAlert(id: String) {
        loadCancellable?.cancel()
        loadCancellable = Network.shared.apollo.fetch(query: GetAlertQuery(alertID: id)) { result in
            self.result = result
        }
    }
    
    func loadAlert() {
        loadAlert(id: alertID)
    }
    
    var body: some View {
        Group {
            switch result {
            case .none:
                ProgressView("Loading")
            case .some(.success(let result)):
                if let alert = result.data?.alert {
                    AlertContentView(alert: alert).frame(maxWidth: .infinity, maxHeight: .infinity).navigationTitle(alert.title)
                } else {
                    Text("Alert not found")
                }
            default:
                Text("Error").foregroundColor(.red)
            }
        }.navigationBarTitleDisplayMode(.inline).onAppear {
            loadAlert()
        }.onChange(of: alertID) { id in
            loadAlert(id: id)
        }
    }
}

extension GetAlertQuery.Data.Alert.`Type`: Equatable {
    public static func ==(lhs: GetAlertQuery.Data.Alert.`Type`, rhs: GetAlertQuery.Data.Alert.`Type`) -> Bool {
        lhs.name == rhs.name
    }
}

extension GetAlertQuery.Data.Alert: Equatable {
    public static func ==(lhs: GetAlertQuery.Data.Alert, rhs: GetAlertQuery.Data.Alert) -> Bool {
        lhs.title == rhs.title && lhs.content == rhs.content && lhs.type == rhs.type
    }
}

struct AlertContentView: UIViewControllerRepresentable {
    var alert: GetAlertQuery.Data.Alert
    
    func makeUIViewController(context: Context) -> AlertContentController {
        let controller = AlertContentController()
        controller.view = WKWebView()
        controller.setupView()
        updateUIViewController(controller, context: context)
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AlertContentController, context: Context) {
        if uiViewController.alert != alert {
            uiViewController.alert = alert
        }
    }
}

class AlertContentController: UIViewController, WKNavigationDelegate {
    
    var webView: WKWebView? {
        view as? WKWebView
    }
    
    var alertsScript: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        configureView()
    }
    
    func setupView() {
        webView?.navigationDelegate = self
        webView?.backgroundColor = .systemBackground
        if #available(iOS 15.0, *) {
            webView?.underPageBackgroundColor = .systemBackground
        }
        webView?.scrollView.alwaysBounceHorizontal = false
        
        if let path = Bundle.main.path(forResource: "alerts-script", ofType: "js") {
            alertsScript = try? String(contentsOfFile: path)
        }
    }
    
    func configureView() {
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
    
    var alert: GetAlertQuery.Data.Alert? {
        didSet {
            if isViewLoaded {
                configureView()
            }
        }
    }

}
