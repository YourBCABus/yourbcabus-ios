//
//  BusTableViewCell.swift
//  YourBCABus
//
//  Created by Anthony Li on 10/22/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import UIKit

class BusTableViewCell: UITableViewCell {
    
    var bus: Bus? {
        didSet {
            configureView()
        }
    }
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var locationView: BusLocationView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func configureView() {
        if let bus = bus {
            nameLabel.text = bus.name == nil ? "(no name)" : bus.name!
            descriptionLabel.text = bus.location == nil ? "Not at BCA" : "Arrived at BCA"
            locationView.location = bus.location
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
