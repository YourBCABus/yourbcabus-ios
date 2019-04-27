//
//  BusStatusTableViewCell.swift
//  YourBCABus
//
//  Created by Anthony Li on 10/27/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import UIKit
import YourBCABus_Embedded

class BusStatusTableViewCell: UITableViewCell {
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var secondaryLabel: UILabel!
    @IBOutlet weak var locationView: BusLocationView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
