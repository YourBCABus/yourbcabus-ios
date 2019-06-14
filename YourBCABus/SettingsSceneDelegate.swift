//
//  SettingsSceneDelegate.swift
//  YourBCABus
//
//  Created by Anthony Li on 6/7/19.
//  Copyright © 2019 YourBCABus. All rights reserved.
//

import UIKit

@available(iOS 13.0, UIKitForMac 13.0, *)
class SettingsSceneDelegate: UIResponder, UISceneDelegate {
    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        window!.rootViewController = storyboard.instantiateViewController(withIdentifier: "settings")
    }
}
