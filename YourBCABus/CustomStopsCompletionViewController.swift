//
//  CustomStopsCompletionViewController.swift
//  YourBCABus
//
//  Created by Anthony Li on 12/8/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import UIKit
import SafariServices
import YourBCABus_Embedded

class CustomStopsCompletionViewController: UIViewController {
    
    var stop: Stop?
    
    static let finishNotificationName = Notification.Name("didDismissCustomStopsViewController")
    
    @IBOutlet weak var finishButton: UIButton?
    @IBOutlet weak var submitButton: UIButton?
    
    var schoolId = Constants.schoolId

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        finishButton?.layer.cornerRadius = 8
        submitButton?.layer.cornerRadius = 8
    }
    
    @IBAction func openPrivacyPolicy(sender: Any?) {
        let safariViewController = SFSafariViewController(url: URL(string: "https://support.yourbcabus.com/privacy-policy")!)
        safariViewController.preferredBarTintColor = UIColor(named: "Primary Dark")!
        safariViewController.preferredControlTintColor = .white
        present(safariViewController, animated: true, completion: nil)
    }
    
    @IBAction func finish(sender: Any?) {
        var stops = try! Stop.getCustomStops()
        stops.append(stop!)
        try! Stop.saveCustomStops(stops)
        
        NotificationCenter.default.post(name: CustomStopsCompletionViewController.finishNotificationName, object: self)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func submitAndFinish(sender: Any?) {
        try! APIService.shared.suggestStop(schoolId: schoolId, stop: stop!, { result in
            if !result.ok {
                print(result.error)
            }
        })
        finish(sender: sender)
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
