//
//  Gradient.swift
//  YourBCABus
//
//  Created by Anthony Li on 11/14/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import UIKit

class GradientView: UIView {
    lazy var primaryGradientLayer: CAGradientLayer = {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = frame
        gradientLayer.colors = [UIColor(named: "Primary")!.cgColor, UIColor(named: "Primary Dark")!.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        return gradientLayer
    }()
    
    func gradientLayer() -> CAGradientLayer {
        return primaryGradientLayer
    }

    override func draw(_ rect: CGRect) {
        gradientLayer().render(in: UIGraphicsGetCurrentContext()!)
    }

}

@IBDesignable class AccentGradientView: GradientView {
    lazy var accentGradientLayer: CAGradientLayer = {
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = frame
        gradientLayer.colors = [UIColor(named: "Accent")!.cgColor, UIColor(named: "Accent 2")!.cgColor]
        gradientLayer.startPoint = CGPoint(x: 1, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0, y: 1)
        return gradientLayer
    }()
    
    override func gradientLayer() -> CAGradientLayer {
        return accentGradientLayer
    }
}
