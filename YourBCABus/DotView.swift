//
//  DotView.swift
//  YourBCABus
//
//  Created by Anthony Li on 2/26/19.
//  Copyright © 2019 YourBCABus. All rights reserved.
//

import UIKit

@IBDesignable class DotView: UIView {
    
    @IBInspectable var borderColor: UIColor {
        get {
            guard let color = layer.borderColor else {
                return UIColor.clear
            }
            
            return UIColor(cgColor: color)
        }
        set {
            layer.borderColor = newValue.cgColor
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable var color: UIColor {
        get {
            guard let color = layer.backgroundColor else {
                return UIColor.clear
            }
            
            return UIColor(cgColor: color)
        }
        set {
            layer.backgroundColor = newValue.cgColor
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.width / 2
    }

}
