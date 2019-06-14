//
//  Gradient.swift
//  YourBCABus
//
//  Created by Anthony Li on 11/14/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import UIKit

class GradientView: UIView {
    func generateGradientLayer() -> CAGradientLayer {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = frame
        gradientLayer.colors = [UIColor(named: "Primary")!.cgColor, UIColor(named: "Primary Dark")!.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        return gradientLayer
    }
    
    lazy var gradientLayer: CAGradientLayer = generateGradientLayer()
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, UIKitForMac 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                gradientLayer = generateGradientLayer()
                setNeedsDisplay()
            }
        }
    }

    override func draw(_ rect: CGRect) {
        gradientLayer.render(in: UIGraphicsGetCurrentContext()!)
    }
}

class AccentGradientView: GradientView {
    override func generateGradientLayer() -> CAGradientLayer {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = frame
        gradientLayer.colors = [UIColor(named: "Accent")!.cgColor, UIColor(named: "Accent 2")!.cgColor]
        gradientLayer.startPoint = CGPoint(x: 1, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0, y: 1)
        return gradientLayer
    }
}
