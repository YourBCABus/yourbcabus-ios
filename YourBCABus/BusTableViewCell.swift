//
//  BusTableViewCell.swift
//  YourBCABus
//
//  Created by Anthony Li on 10/22/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import UIKit

class BusTableViewCell: UITableViewCell {
    var starListener: BusManagerStarListener!
    
    func setupListener() {
        starListener = BusManagerStarListener(listener: { [unowned self] in
            self.configureStarButton(starred: BusManager.shared.isStarred(bus: self.bus!._id))
        })
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupListener()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupListener()
    }
    
    var bus: Bus? {
        willSet {
            if let id = bus?._id {
                BusManager.shared.removeStarListener(starListener, for: id)
            }
        }
        didSet {
            configureView()
            if let id = bus?._id {
                BusManager.shared.addStarListener(starListener, for: id)
            }
        }
    }
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var locationView: BusLocationView!
    @IBOutlet weak var starButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func configureView() {
        if let bus = bus {
            nameLabel.text = bus.name == nil ? "(no name)" : bus.name!
            descriptionLabel.text = bus.location == nil ? "Not at BCA" : "Arrived at BCA"
            locationView.location = bus.location
            configureStarButton(starred: BusManager.shared.isStarred(bus: bus._id))
        }
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    @IBAction func toggleStar(sender: UIButton?) {
        if let id = bus?._id {
            BusManager.shared.toggleStar(for: id)
        }
    }
    
    func configureStarButton(starred: Bool) {
        starButton.tintColor = starred ? UIColor(named: "Accent") : UIColor.lightGray
    }
    
    deinit {
        if let id = bus?._id {
            BusManager.shared.removeStarListener(starListener, for: id)
        }
    }

}
