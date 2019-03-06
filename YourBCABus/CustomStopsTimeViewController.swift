//
//  CustomStopsTimeViewController.swift
//  YourBCABus
//
//  Created by Anthony Li on 12/8/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import UIKit
import CoreLocation
import YourBCABus_Embedded

class CustomStopsTimeViewController: UIViewController {
    
    var bus: Bus?
    var placemark: CLPlacemark?
    
    @IBOutlet weak var timePicker: UIDatePicker!
    @IBOutlet weak var continueButton: UIButton?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        continueButton?.layer.cornerRadius = 8
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? CustomStopsCompletionViewController {
            destination.stop = Stop(customStopAt: Coordinate(from: placemark!.location!.coordinate), bus: bus!._id, arrivesAt: timePicker.date, name: placemark!.name)
        }
    }

}
