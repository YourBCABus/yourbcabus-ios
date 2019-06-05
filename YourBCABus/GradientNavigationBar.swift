//
//  GradientNavigationBar.swift
//  YourBCABus
//
//  Created by Anthony Li on 10/19/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import UIKit
import YourBCABus_Embedded

func createGradient() -> UIImage {
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
    
    return image
}

class GradientNavigationBar: UINavigationBar {
    
    private static var gradient: UIColor! = UIColor(patternImage: createGradient())
    private static var gradientImage: UIImage = createGradient()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateBarTint()
    }
    
    func updateBarTint() {
        if #available(iOS 13.0, UIKitForMac 13.0, *) {
            if traitCollection.userInterfaceStyle == .dark {
                // standardAppearance.backgroundColor = nil
            } else {
                // standardAppearance.backgroundImage = GradientNavigationBar.gradientImage
            }
        } else {
            barTintColor = GradientNavigationBar.gradient
            barStyle = .black
        }
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        self.tintColor = UIColor.white
    }
    
}
