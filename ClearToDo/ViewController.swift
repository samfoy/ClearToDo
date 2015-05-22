
//
//  ViewController.swift
//  ClearToDo
//
//  Created by Samuel Painter on 5/21/15.
//  Copyright (c) 2015 Samuel Painter. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, TableViewCellDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    var toDoItems = [ToDoItem]()
    
    let pinchRecognizer = UIPinchGestureRecognizer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pinchRecognizer.addTarget(self, action: "handlePinch:")
        tableView.addGestureRecognizer(pinchRecognizer)
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.registerClass(TableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.separatorStyle = .None
        tableView.backgroundColor = UIColor.blackColor()
        tableView.rowHeight = 50.0
        // Do any additional setup after loading the view, typically from a nib.
        
        if toDoItems.count > 0 {
            return
        }
        toDoItems.append(ToDoItem(text: "Swipe left to delete"))
        toDoItems.append(ToDoItem(text: "Swipe right to complete"))
        toDoItems.append(ToDoItem(text: "Pull down to add to the top"))
        toDoItems.append(ToDoItem(text: "Pinch apart to add between"))
    }
    
    // MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return toDoItems.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! TableViewCell
        let item = toDoItems[indexPath.row]
        cell.selectionStyle = .None
        cell.delegate = self
        cell.toDoItem = item
        return cell
    }
    
    //MARK: - add, delete, edit methods
    
    func cellDidBeginEditing(editingCell: TableViewCell) {
        var editingOffset = tableView.contentOffset.y - editingCell.frame.origin.y as CGFloat
        let visibleCells = tableView.visibleCells() as! [TableViewCell]
        for cell in visibleCells {
            UIView.animateWithDuration(0.3, animations: {() in cell.transform = CGAffineTransformMakeTranslation(0, editingOffset)
                if cell != editingCell {
                    cell.alpha = 0.3
                }
            })
        }
    }
    
    func cellDidEndEditing(editingCell: TableViewCell) {
        let visibleCells = tableView.visibleCells() as! [TableViewCell]
        for cell: TableViewCell in visibleCells {
            UIView.animateWithDuration(0.3, animations: {() in cell.transform = CGAffineTransformIdentity
                if cell !== editingCell {
                    cell.alpha = 1.0
                }
            })
        }
        if editingCell.toDoItem!.text == "" {
            toDoItemDeleted(editingCell.toDoItem!)
        }
    }
    
    func toDoItemDeleted(toDoItem: ToDoItem) {
        let index = (toDoItems as NSArray).indexOfObject(toDoItem)
        if index == NSNotFound { return }
        
        toDoItems.removeAtIndex(index)
        
//        //animate
//        tableView.beginUpdates()
//        let indexPathForRow = NSIndexPath(forRow: index, inSection: 0)
//        tableView.deleteRowsAtIndexPaths([indexPathForRow], withRowAnimation: .Fade)
//        tableView.endUpdates()
        
        // new animation
        let visibleCells = tableView.visibleCells() as! [TableViewCell]
        let lastView = visibleCells[visibleCells.count - 1] as TableViewCell
        var delay = 0.0
        var startAnimating = false
        
        for i in 0..<visibleCells.count {
            let cell = visibleCells[i]
            if startAnimating {
                UIView.animateWithDuration(0.3, delay: delay, options: .CurveEaseInOut, animations: {
                    () in cell.frame = CGRectOffset(cell.frame, 0.0, -cell.frame.size.height)
                    }, completion: {(finished: Bool) in
                        if (cell == lastView) {
                            self.tableView.reloadData()
                        }
                })
                delay += 0.03
            }
            if cell.toDoItem === toDoItem {
                startAnimating = true
                cell.hidden = true
            }
        }
        
        tableView.beginUpdates()
        let indexPathForRow = NSIndexPath(forRow: index, inSection: 0)
        tableView.deleteRowsAtIndexPaths([indexPathForRow], withRowAnimation: .Fade)
        tableView.endUpdates()
    }
    
    func toDoItemAdded() {
        toDoItemAddedAtIndex(0)
    }
    
    func toDoItemAddedAtIndex(index: Int) {
        let toDoItem = ToDoItem(text: "")
        toDoItems.insert(toDoItem, atIndex: index)
        tableView.reloadData()
        
        var editCell: TableViewCell
        let visibleCells = tableView.visibleCells() as! [TableViewCell]
        for cell in visibleCells {
            if (cell.toDoItem === toDoItem) {
                editCell = cell
                editCell.label.becomeFirstResponder()
                break
            }
        }
    }
    
    // MARK: - pinch-to-add methods
    
    var pinchInProgress = false
    
    struct TouchPoints {
        var upper: CGPoint
        var lower: CGPoint
    }
    
    var upperCellIndex = -100
    var lowerCellIndex = -100
    
    var initialTouchPoints: TouchPoints!
    var pinchExceededRequiredDistance = false
    
    func handlePinch(recognizer: UIPinchGestureRecognizer) {
        if recognizer.state == .Began {
            pinchStarted(recognizer)
        }
        if recognizer.state == .Changed && pinchInProgress && recognizer.numberOfTouches() == 2 {
            pinchChanged(recognizer)
        }
        if recognizer.state == .Ended {
            pinchEnded(recognizer)
        }
    }
    
    func pinchStarted(recognizer: UIPinchGestureRecognizer) {
        initialTouchPoints = getNormalizedTouchPoints(recognizer)
        
        upperCellIndex = -100
        lowerCellIndex = -100
        let visibleCells = tableView.visibleCells() as! [TableViewCell]
        for i in 0..<visibleCells.count {
            let cell = visibleCells[i]
            if viewContainsPoint(cell, point: initialTouchPoints.upper) {
                upperCellIndex = i
            }
            if viewContainsPoint(cell, point: initialTouchPoints.lower) {
                lowerCellIndex = i
            }
        }
        
        if abs(upperCellIndex - lowerCellIndex) == 1 {
            pinchInProgress = true
            let precedingCell = visibleCells[upperCellIndex]
            placeHolderCell.frame = CGRectOffset(precedingCell.frame, 0.0, tableView.rowHeight / 2.0)
            placeHolderCell.backgroundColor = precedingCell.backgroundColor
            tableView.insertSubview(placeHolderCell, atIndex: 0)
        }
    }
    
    func pinchChanged(recognizer: UIPinchGestureRecognizer) {
        let currentTouchPoints = getNormalizedTouchPoints(recognizer)
        
        let upperDelta = currentTouchPoints.upper.y - initialTouchPoints.upper.y
        let lowerDelta = initialTouchPoints.lower.y - currentTouchPoints.lower.y
        let delta = -min(0, min(upperDelta, lowerDelta))
        
        let visibleCells = tableView.visibleCells() as! [TableViewCell]
        for i in 0..<visibleCells.count {
            let cell = visibleCells[i]
            if i <= upperCellIndex {
                cell.transform = CGAffineTransformMakeTranslation(0, -delta)
            }
            if i >= lowerCellIndex {
                cell.transform = CGAffineTransformMakeTranslation(0, delta)
            }
        }
        
        let gapSize = delta * 2
        let cappedGapSize = min(gapSize, tableView.rowHeight)
        let precedingCell = visibleCells[upperCellIndex]
        placeHolderCell.transform = CGAffineTransformMakeScale(1.0, cappedGapSize / tableView.rowHeight)
        placeHolderCell.label.text = gapSize > tableView.rowHeight ? "Release to add item" : "Pull apart to add item"
        placeHolderCell.alpha = min(1.0, gapSize / tableView.rowHeight)
        
        pinchExceededRequiredDistance = gapSize > tableView.rowHeight
    }
    
    func pinchEnded(recognizer: UIPinchGestureRecognizer) {
        pinchInProgress = false
        
        placeHolderCell.transform = CGAffineTransformIdentity
        placeHolderCell.removeFromSuperview()
        
        if pinchExceededRequiredDistance {
            pinchExceededRequiredDistance = false
            
            let visibleCells = self.tableView.visibleCells() as! [TableViewCell]
            for cell in visibleCells {
                cell.transform = CGAffineTransformIdentity
            }
            let indexOffset = Int(floor(tableView.contentOffset.y / tableView.rowHeight))
            toDoItemAddedAtIndex(lowerCellIndex + indexOffset)
        } else {
            UIView.animateWithDuration(0.2, delay: 0.0, options: .CurveEaseInOut, animations: {() in let visibleCells = self.tableView.visibleCells() as! [TableViewCell]
                for cell in visibleCells {
                    cell.transform = CGAffineTransformIdentity
                }}, completion: nil)
        }
        
    
        
        
    }
    
    func getNormalizedTouchPoints(recognizer: UIGestureRecognizer) -> TouchPoints {
        var pointOne = recognizer.locationOfTouch(0, inView: tableView)
        var pointTwo = recognizer.locationOfTouch(1, inView: tableView)
        if pointOne.y > pointTwo.y {
            let temp = pointOne
            pointOne = pointTwo
            pointTwo = temp
        }
        return TouchPoints(upper: pointOne,lower: pointTwo)
    }
    
    func viewContainsPoint(view: UIView, point: CGPoint) -> Bool {
        let frame = view.frame
        return (frame.origin.y < point.y) && (frame.origin.y + (frame.size.height) > point.y)
    }
    
    // MARK: - UIScrollViewDelegate methods
    let placeHolderCell = TableViewCell(style: .Default, reuseIdentifier: "cell")
    var pullDownInProgress = false
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        pullDownInProgress = scrollView.contentOffset.y  <= 0.0
        placeHolderCell.backgroundColor = UIColor.redColor()
        if pullDownInProgress {
            tableView.insertSubview(placeHolderCell, atIndex: 0)
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        var scrollViewContentOffSetY = scrollView.contentOffset.y
        
        if pullDownInProgress && scrollView.contentOffset.y <= 0.0 {
            placeHolderCell.frame = CGRect(x:0, y: -tableView.rowHeight, width: tableView.frame.size.width, height: tableView.rowHeight)
            placeHolderCell.label.text = -scrollViewContentOffSetY > tableView.rowHeight ?
                "Release to add item" : "Pull to add item"
            placeHolderCell.alpha = min(1.0, -scrollViewContentOffSetY / tableView.rowHeight)
        } else {
            pullDownInProgress = false
        }
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if pullDownInProgress && -scrollView.contentOffset.y > tableView.rowHeight {
            toDoItemAdded()
        }
        pullDownInProgress = false
        placeHolderCell.removeFromSuperview()
    }
    
    // MARK: - TableViewDelegate methods
    
    func colorForIndex(index: Int) -> UIColor {
        let itemCount = toDoItems.count - 1
        let val = (CGFloat(index) / CGFloat(itemCount)) * 0.6
        return UIColor(red: 1.0, green: val, blue: 0.0, alpha: 1.0)
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.backgroundColor = colorForIndex(indexPath.row)
    }

}
