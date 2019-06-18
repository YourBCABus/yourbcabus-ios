//
//  RoundedButton.swift
//  YourBCABus
//
//  Created by Anthony Li on 6/15/19.
//  Copyright © 2019 YourBCABus. All rights reserved.
//

import UIKit

@IBDesignable class RoundedButton: UIButton {
    
    @IBInspectable var cornerRadius: CGFloat = 4
    
    private func sharedInit() {
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = true
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        sharedInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        sharedInit()
    }

}
