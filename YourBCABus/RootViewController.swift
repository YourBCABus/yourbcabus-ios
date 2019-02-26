//
//  RootViewController.swift
//  YourBCABus
//
//  Created by Anthony Li on 12/10/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import UIKit

class RootViewController: UISplitViewController {

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let data = UserDefaults.standard.data(forKey: AppDelegate.currentRouteDefaultKey) {
            let decoder = PropertyListDecoder()
            let route = try! decoder.decode(Route.self, from: data)
            
            let controller = UIStoryboard(name: "Navigation", bundle: nil).instantiateViewController(withIdentifier: "YBBNavigationModalViewController") as! ModalNavigationViewController
            controller.route = route
            controller.modalPresentationStyle = .fullScreen
            present(controller, animated: false, completion: nil)
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
