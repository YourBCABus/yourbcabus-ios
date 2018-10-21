//
//  DetailViewController.swift
//  YourBCABus
//
//  Created by Anthony Li on 10/19/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var detailDescriptionLabel: UILabel!
    
    var detailItem: Bus? {
        didSet {
            configureView()
        }
    }

    func configureView() {
        // Update the user interface for the detail item.
        if let bus = detailItem {
            if let label = detailDescriptionLabel {
                navigationItem.title = bus.description
                label.text = bus.description
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        configureView()
    }


}

