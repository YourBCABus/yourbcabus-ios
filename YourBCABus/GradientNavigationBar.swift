//
//  GradientNavigationBar.swift
//  YourBCABus
//
//  Created by Anthony Li on 10/19/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import UIKit

func createGradient() -> UIImage? {
    let gradientLayer = CAGradientLayer()
    gradientLayer.frame = UIScreen.main.bounds
    gradientLayer.colors = [UIColor(named: "Primary")!.cgColor, UIColor(named: "Primary Dark")!.cgColor]
    gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
    gradientLayer.endPoint = CGPoint(x: 0.7, y: 0.2)
    
    UIGraphicsBeginImageContext(UIScreen.main.bounds.size)
    gradientLayer.render(in: UIGraphicsGetCurrentContext()!)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return image
}

class GradientNavigationBar: UINavigationBar {
    
    private static var gradient: UIImage? = createGradient()
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        self.barTintColor = UIColor(patternImage: GradientNavigationBar.gradient!)
    }

}
