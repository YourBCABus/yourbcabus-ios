//
//  SettingsViewController.swift
//  YourBCABus
//
//  Created by Anthony Li on 10/26/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }
    
    @IBAction func done(sender: UIBarButtonItem?) {
        dismiss(animated: true, completion: nil)
    }

}
