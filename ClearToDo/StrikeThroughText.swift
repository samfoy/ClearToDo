//
//  StrikeThroughText.swift
//  ClearToDo
//
//  Created by Samuel Painter on 5/21/15.
//  Copyright (c) 2015 Samuel Painter. All rights reserved.
//

import UIKit
import QuartzCore

class StrikeThroughText: UITextField {
    
    let strikeThroughLayer: CALayer
    var strikeThrough: Bool {
        didSet {
            strikeThroughLayer.hidden = !strikeThrough
            if strikeThrough {
                resizeStrikeThrough()
            }
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    override init(frame: CGRect) {
        strikeThroughLayer = CALayer()
        strikeThroughLayer.backgroundColor = UIColor.whiteColor().CGColor
        strikeThroughLayer.hidden = true
        strikeThrough = false
        
        super.init(frame: frame)
        layer.addSublayer(strikeThroughLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        resizeStrikeThrough()
    }
    
    let kStrikeOutThickness: CGFloat = 2.0
    
    func resizeStrikeThrough() {
        let textSize = text!.sizeWithAttributes([NSFontAttributeName: font])
        strikeThroughLayer.frame = CGRect(x: 0, y: bounds.size.height / 2, width: textSize.width, height: kStrikeOutThickness)
    }
}
