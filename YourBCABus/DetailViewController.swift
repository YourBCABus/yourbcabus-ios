//
//  DetailViewController.swift
//  YourBCABus
//
//  Created by Anthony Li on 10/19/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import UIKit
import MapKit

class DetailViewController: UIViewController {
        
    var detailItem: Bus? {
        didSet {
            configureView()
        }
    }

    func configureView() {
        // Update the user interface for the detail item.
        if let bus = detailItem {
            navigationItem.title = bus.description
            (children.first(where: { controller in
                return controller is MapViewController
            }) as? MapViewController)?.detailBus = bus._id
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        
        // Do any additional setup after loading the view, typically from a nib.
                
        configureView()
    }


}

