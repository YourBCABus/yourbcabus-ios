//
//  SceneDelegate.swift
//  YourBCABus
//
//  Created by Anthony Li on 6/7/19.
//  Copyright © 2019 YourBCABus. All rights reserved.
//

import UIKit

@available(iOS 13.0, UIKitForMac 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate, UISplitViewControllerDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let splitViewController = window!.rootViewController as? UISplitViewController {
            let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as! UINavigationController
            navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
            navigationController.topViewController!.navigationItem.leftItemsSupplementBackButton = true
            splitViewController.delegate = self
            splitViewController.presentsWithGesture = false
            // splitViewController.preferredDisplayMode = .allVisible
        
            splitViewController.primaryBackgroundStyle = .sidebar
        }
    }
    
    // MARK: - Split view
    
    private var didPerformInitialCollapse = false
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController:UIViewController, onto primaryViewController:UIViewController) -> Bool {
        let didPerform = didPerformInitialCollapse
        didPerformInitialCollapse = true
        return !didPerform
    }
}
