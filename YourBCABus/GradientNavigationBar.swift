//
//  GradientNavigationBar.swift
//  YourBCABus
//
//  Created by Anthony Li on 10/19/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import UIKit

func createGradient() -> UIColor {
    let gradientLayer = CAGradientLayer()
    let size = max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
    gradientLayer.frame = CGRect(x: 0, y: 0, width: size, height: size)
    gradientLayer.colors = [UIColor(named: "Primary")!.cgColor, UIColor(named: "Primary Dark")!.cgColor]
    gradientLayer.startPoint = CGPoint(x: 0.1, y: 0)
    gradientLayer.endPoint = CGPoint(x: 0.3, y: 0.1)
    
    UIGraphicsBeginImageContext(CGSize(width: size, height: size))
    gradientLayer.render(in: UIGraphicsGetCurrentContext()!)
    let image = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    
    return UIColor(patternImage: image)
}

class GradientNavigationBar: UINavigationBar {
    
    private static var gradient: UIColor! = createGradient()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.barTintColor = GradientNavigationBar.gradient
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        self.tintColor = UIColor.white
    }
    
}
