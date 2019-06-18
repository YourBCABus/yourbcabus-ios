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
        
        if UserDefaults.standard.integer(forKey: AppDelegate.lastSetupDoneDefaultsKey) < AppDelegate.setupNumber {
            if let controller = UIStoryboard(name: "Onboarding", bundle: nil).instantiateInitialViewController() {
                controller.modalPresentationStyle = .fullScreen
                present(controller, animated: false, completion: nil)
            }
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
