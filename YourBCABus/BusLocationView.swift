//
//  BusLocationView.swift
//  YourBCABus
//
//  Created by Anthony Li on 10/22/18.
//  Copyright © 2018 YourBCABus. All rights reserved.
//

import UIKit

class BusLocationView: UIView {
    
    var location: String? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var circleColor = UIColor(named: "Primary")!
    var textColor = UIColor.white
    
    var noLocationCircleColor = UIColor(named: "Background")!
    var noLocationTextColor = UIColor(named: "Primary")!
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
        let fontSize: CGFloat = 24
        
        let circleCol: UIColor
        let textCol: UIColor
        let font: UIFont
        let text: String
        if let location = location {
            circleCol = circleColor
            textCol = textColor
            font = UIFont.systemFont(ofSize: fontSize, weight: .heavy)
            text = location
        } else {
            circleCol = noLocationCircleColor
            textCol = noLocationTextColor
            font = UIFont.systemFont(ofSize: fontSize, weight: .thin)
            text = "?"
        }
        
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(circleCol.cgColor)
        context.fillEllipse(in: rect)
        
        let style = NSMutableParagraphStyle()
        style.alignment = .center
        
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: textCol, .paragraphStyle: style.copy()]

        let drawText = text as NSString
        let size = drawText.size(withAttributes: attributes)
        (text as NSString).draw(in: CGRect(origin: rect.offsetBy(dx: 0, dy: (rect.height - size.height) / 2).origin, size: CGSize(width: rect.size.width, height: size.height)), withAttributes: attributes)
    }

}