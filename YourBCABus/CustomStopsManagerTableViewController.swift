
//
//  CustomStopsManagerTableViewController.swift
//  YourBCABus
//
//  Created by Anthony Li on 12/8/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import UIKit
import YourBCABus_Embedded

class CustomStopsManagerTableViewController: UITableViewController {
    
    var customStops = [Stop]()
    private var token: NotificationToken?

    override func viewDidLoad() {
        super.viewDidLoad()
        customStops = try! Stop.getCustomStops()
        editButtonItem.isEnabled = self.customStops.count > 0
        isEditing = false
        
        token = NotificationCenter.default.observe(name: CustomStopsCompletionViewController.finishNotificationName, object: nil, queue: nil, using: { [unowned self] notification in
            self.customStops = try! Stop.getCustomStops()
            self.tableView.reloadData()
            
            self.editButtonItem.isEnabled = self.customStops.count > 0
        })
        
        navigationItem.rightBarButtonItem = editButtonItem
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return customStops.count > 0 ? 2 : 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 1 ? 1 : customStops.count + 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 1 {
            return tableView.dequeueReusableCell(withIdentifier: "DeleteAllCell")!
        } else if indexPath.row == customStops.count {
            return tableView.dequeueReusableCell(withIdentifier: "AddStopCell")!
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "CustomStopCell")!
            let stop = customStops[indexPath.row]
            
            cell.textLabel?.text = stop.name ?? stop._id
            if let name = BusManager.shared.buses.first(where: {$0._id == stop.bus_id})?.name {
                cell.detailTextLabel?.text = "On bus \(name)"
            } else {
                cell.detailTextLabel?.text = nil
            }
            
            return cell
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            let alert = UIAlertController(title: "Delete all custom stops?", message: "You cannot undo this action.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { action in
                self.customStops = []
                try! Stop.saveCustomStops(self.customStops)
                
                self.tableView.reloadData()
                
                self.isEditing = false
                self.editButtonItem.isEnabled = false
            }))
            
            present(alert, animated: true, completion: nil)
        } else if indexPath.row == customStops.count {
            performSegue(withIdentifier: "addCustomStop", sender: tableView)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 0 && indexPath.row < customStops.count
    }

    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            customStops.remove(at: indexPath.row)
            try! Stop.saveCustomStops(customStops)
            
            if customStops.count < 1 {
                tableView.reloadData()
                isEditing = false
                editButtonItem.isEnabled = false
            } else {
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
        }
    }

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
