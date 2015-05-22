//
//  TableViewCell.swift
//  ClearToDo
//
//  Created by Samuel Painter on 5/21/15.
//  Copyright (c) 2015 Samuel Painter. All rights reserved.
//

import UIKit
import QuartzCore

protocol TableViewCellDelegate {
    func toDoItemDeleted(toDoItem: ToDoItem)
    func cellDidBeginEditing(editingCell: TableViewCell)
    func cellDidEndEditing(editingCell: TableViewCell)
}

class TableViewCell: UITableViewCell, UITextFieldDelegate {
    
    let gradientLayer = CAGradientLayer()
    
    var originalCenter = CGPoint()
    var deleteOnDragRelease = false
    var completeOnDragRelease = false
    
    var tickLabel: UILabel!, crossLabel: UILabel!
    
    let label: StrikeThroughText
    var itemCompleteLayer = CALayer()
    
    var delegate: TableViewCellDelegate?
    var toDoItem: ToDoItem? {
        didSet {
            label.text = toDoItem!.text
            label.strikeThrough = toDoItem!.completed
            itemCompleteLayer.hidden = !label.strikeThrough
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("NSCoding not supported")
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        label = StrikeThroughText(frame: CGRect.nullRect)
        label.textColor = UIColor.whiteColor()
        label.font = UIFont.boldSystemFontOfSize(16)
        label.backgroundColor = UIColor.clearColor()
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        label.delegate = self
        label.contentVerticalAlignment = .Center
        
        addSubview(label)
        selectionStyle = .None
        
        gradientLayer.frame = bounds
        let color1 = UIColor(white: 1.0, alpha: 0.2).CGColor as CGColorRef
        let color2 = UIColor(white: 1.0, alpha: 0.1).CGColor as CGColorRef
        let color3 = UIColor.clearColor().CGColor as CGColorRef
        let color4 = UIColor(white: 0.0, alpha: 0.1).CGColor as CGColorRef
        
        gradientLayer.colors = [color1, color2, color3, color4]
        gradientLayer.locations = [0.0,0.01, 0.95, 1.0]
        layer.insertSublayer(gradientLayer, atIndex: 0)
        
        tickLabel = createCueLabel()
        tickLabel.text = "\u{2713}"
        tickLabel.textAlignment = .Right
        addSubview(tickLabel)
        
        crossLabel = createCueLabel()
        crossLabel.text = "\u{2717}"
        crossLabel.textAlignment = .Left
        addSubview(crossLabel)
        
        itemCompleteLayer = CALayer(layer: layer)
        itemCompleteLayer.hidden = true
        itemCompleteLayer.backgroundColor = UIColor(red: 0.6, green: 0.0, blue: 0.6, alpha: 1.0).CGColor
        layer.insertSublayer(itemCompleteLayer, atIndex: 0)
        
        var recognizer = UIPanGestureRecognizer(target: self, action: "handlePan:")
        recognizer.delegate = self
        addGestureRecognizer(recognizer)
    }

    let kLabelLeftMargin: CGFloat = 15.0
    let kLabelTopMargin: CGFloat = 10.0
    let kUICuesMargin: CGFloat = 10.0, kUICuesWidth: CGFloat = 50.0
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
        itemCompleteLayer.frame = bounds
        label.frame = CGRect(x: kLabelLeftMargin, y: kLabelTopMargin, width: bounds.size.width - (kLabelLeftMargin * 2), height: bounds.size.height - (2 * kLabelTopMargin))
        
        tickLabel.frame = CGRect(x: -kUICuesWidth - kUICuesMargin, y: 0, width: kUICuesWidth, height: bounds.size.height)
        crossLabel.frame = CGRect(x: bounds.size.width + kUICuesMargin, y: 0, width: kUICuesWidth, height: bounds.size.height)
    }
    
    func createCueLabel() -> UILabel {
        let label = UILabel(frame: CGRect.nullRect)
        label.textColor = UIColor.whiteColor()
        label.font = UIFont.boldSystemFontOfSize(32.0)
        label.backgroundColor = UIColor.clearColor()
        return label
    }
    
    func handlePan(recognizer: UIPanGestureRecognizer) {
        if recognizer.state == .Began {
            originalCenter = center
        }
        
        if recognizer.state == .Changed {
            let translation = recognizer.translationInView(self)
            center = CGPointMake(originalCenter.x + translation.x, originalCenter.y)
            deleteOnDragRelease = frame.origin.x < -frame.size.width / 2.0
            completeOnDragRelease = frame.origin.x > frame.size.width / 2.0
            
            let cueAlpha = fabs(frame.origin.x) / (frame.size.width / 2.0)
            tickLabel.alpha = cueAlpha
            crossLabel.alpha = cueAlpha
            
            tickLabel.textColor = completeOnDragRelease ? UIColor.greenColor() : UIColor.whiteColor()
            crossLabel.textColor = deleteOnDragRelease ? UIColor.redColor() : UIColor.whiteColor()
        }
        
        if recognizer.state == .Ended {
            let originalFrame = CGRect(x: 0, y: frame.origin.y, width: bounds.size.width, height: bounds.size.height)
            
            if deleteOnDragRelease {
                if delegate != nil && toDoItem != nil {
                    delegate!.toDoItemDeleted(toDoItem!)
                }
            } else if completeOnDragRelease {
                if toDoItem != nil {
                    toDoItem!.completed = true
                }
                label.strikeThrough = true
                itemCompleteLayer.hidden = false
                UIView.animateWithDuration(0.2, animations: {self.frame = originalFrame})
            } else {
                UIView.animateWithDuration(0.2, animations: {self.frame = originalFrame})
            }
        }
    }
    
    override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
            let translation = panGestureRecognizer.translationInView(superview!)
            if fabs(translation.x) > fabs(translation.y) {
                return true
            }
            return false
        }
        return false
    }
    
    // MARK: - UITextFieldDelegate Methods
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        if toDoItem != nil {
            return !toDoItem!.completed
        }
        return false
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        if toDoItem != nil {
            toDoItem!.text = textField.text
        }
        if delegate != nil {
            delegate!.cellDidEndEditing(self)
        }
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        if delegate != nil {
            delegate!.cellDidBeginEditing(self)
        }
    }

}
