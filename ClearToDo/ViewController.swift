
//
//  ViewController.swift
//  ClearToDo
//
//  Created by Samuel Painter on 5/21/15.
//  Copyright (c) 2015 Samuel Painter. All rights reserved.
//

import UIKit
import CoreData

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, TableViewCellDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    var toDoItems = [ToDoItem]()
    
    let pinchRecognizer = UIPinchGestureRecognizer()
    let longPressRecognizer = UILongPressGestureRecognizer()
    let defaults = NSUserDefaults.standardUserDefaults()
    let moc = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pinchRecognizer.addTarget(self, action: "handlePinch:")
        tableView.addGestureRecognizer(pinchRecognizer)
        
        longPressRecognizer.addTarget(self, action: "handleLongPress:")
        longPressRecognizer.minimumPressDuration = 0.5
        longPressRecognizer.delaysTouchesBegan = true
        tableView.addGestureRecognizer(longPressRecognizer)
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.registerClass(TableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.separatorStyle = .None
        tableView.backgroundColor = UIColor.blackColor()
        tableView.rowHeight = 50.0
        tableView.userInteractionEnabled = true
        // Do any additional setup after loading the view, typically from a nib.
        
        if toDoItems.count > 0 {
            return
        }
        
        if !defaults.boolForKey("firstlaunch 1.0") {
            defaults.setBool(true, forKey: "firstlaunch 1.0")
            defaults.synchronize()
            
//            toDoItems.append(ToDoItem(text: "Swipe left to delete"))
//            toDoItems.append(ToDoItem(text: "Swipe right to complete"))
//            toDoItems.append(ToDoItem(text: "Pull down to add to the top"))
//            toDoItems.append(ToDoItem(text: "Pinch apart to add between"))
            toDoItems.append(ToDoItem.createInManagedObjectContext(moc, text: "Swipe left to delete"))
            toDoItems.append(ToDoItem.createInManagedObjectContext(moc, text: "Swipe right to complete"))
            toDoItems.append(ToDoItem.createInManagedObjectContext(moc, text: "Pull down to add to the top"))
            toDoItems.append(ToDoItem.createInManagedObjectContext(moc, text: "Pinch apart to add between"))
            save()
        }
        
        fetchItems()
       
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
        if item.completed {
            cell.label.strikeThrough = true
            cell.itemCompleteLayer.hidden = false
        }
        return cell
    }
    
    func fetchItems() {
        let request = NSFetchRequest(entityName: "ToDoItem")
        if let results = moc.executeFetchRequest(request, error: nil) as? [ToDoItem] {
            toDoItems = results
        }
    }
    
    func save() {
        var error: NSError?
        if !moc.save(&error) {
            NSLog("Unresolved error \(error), \(error!.userInfo)")
        }
    }
    
    // MARK: - add, delete, edit methods
    
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
        save()
    }
    
    func toDoItemDeleted(toDoItem: ToDoItem) {
        let index = (toDoItems as NSArray).indexOfObject(toDoItem)
        if index == NSNotFound { return }
        toDoItems.removeAtIndex(index)
        moc.deleteObject(toDoItem)
        
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
        tableView.reloadData()
        save()
    }
    
    func toDoItemCompleted(toDoItem: ToDoItem) {
        save()
    }
    
    func toDoItemAdded() {
        toDoItemAddedAtIndex(0)
    }
    
    func toDoItemAddedAtIndex(index: Int) {
//        let toDoItem = ToDoItem(text: "")
        let toDoItem = ToDoItem.createInManagedObjectContext(moc, text: "")
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
        save()
    }
    
    // MARK: - reorder methods
    var longPressLocation: CGPoint!
    var indexPath: NSIndexPath!
    var cellSnapshot: UIView!
    var initialIndexPath: NSIndexPath!
    
    func handleLongPress(recognizer: UILongPressGestureRecognizer) {
        switch recognizer.state {
        case .Began:
            longPressStarted(recognizer)
        case .Changed:
            longPressChanged(recognizer)
        default:
            longPressUnchanged(recognizer)
        }
    }
    
    func longPressStarted(recognizer: UILongPressGestureRecognizer) {
        longPressLocation = recognizer.locationInView(tableView)
        indexPath = tableView.indexPathForRowAtPoint(longPressLocation)
        initialIndexPath = indexPath
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! TableViewCell
        cellSnapshot = snapShot(cell)
        var center = cell.center
        cellSnapshot.center = center
        cellSnapshot.alpha = 0.0
        tableView.addSubview(cellSnapshot)
        
        UIView.animateWithDuration(0.2, animations: {
            () in center.y = self.longPressLocation.y
            self.cellSnapshot.center = center
            self.cellSnapshot.transform = CGAffineTransformMakeScale(1.05,1.05)
            self.cellSnapshot.alpha = 0.95
            cell.alpha = 0.0
            }, completion: {
                (finished) in
                if finished {
                    cell.hidden = true
                }
        })
    }
    
    func longPressChanged(recognizer: UILongPressGestureRecognizer) {
        longPressLocation = recognizer.locationInView(tableView)
        indexPath = tableView.indexPathForRowAtPoint(longPressLocation)
        var center = cellSnapshot.center
        center.y = longPressLocation.y
        cellSnapshot.center = center
        
        if indexPath != nil && indexPath != initialIndexPath {
            swap(&toDoItems[indexPath.row], &toDoItems[initialIndexPath.row])
            tableView.moveRowAtIndexPath(initialIndexPath, toIndexPath: indexPath)
            initialIndexPath = indexPath
            tableView.reloadData()
        }
    }
    
    func longPressUnchanged(recognizer: UILongPressGestureRecognizer) {
        let cell = tableView.cellForRowAtIndexPath(initialIndexPath) as! TableViewCell
        cell.hidden = false
        cell.alpha = 0.0
        UIView.animateWithDuration(0.2, animations: {
            () in self.cellSnapshot.center = cell.center
            self.cellSnapshot.transform = CGAffineTransformIdentity
            self.cellSnapshot.alpha = 0.0
            cell.alpha = 1.0
            }, completion: {
                (finished) in
                if finished {
                    self.initialIndexPath = nil
                    self.cellSnapshot.removeFromSuperview()
                    self.cellSnapshot = nil
                }
        })
    }
    
    func snapShot(inputView: UIView) -> UIView {
        UIGraphicsBeginImageContextWithOptions(inputView.bounds.size, false, 0.0)
        inputView.layer.renderInContext(UIGraphicsGetCurrentContext())
        let image = UIGraphicsGetImageFromCurrentImageContext() as UIImage
        UIGraphicsEndImageContext()
        let snapShot: UIView = UIImageView(image: image)
        snapShot.layer.masksToBounds = false
        snapShot.layer.cornerRadius = 0.0
        snapShot.layer.shadowOffset = CGSizeMake(-5.0, 0.0)
        snapShot.layer.shadowRadius = 5.0
        snapShot.layer.shadowOpacity = 0.3
        return snapShot
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
        placeHolderCell.backgroundColor = UIColor.blueColor()
        if pullDownInProgress {
            tableView.insertSubview(placeHolderCell, atIndex: 0)
        }
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        var scrollViewContentOffSetY = scrollView.contentOffset.y
        
        if pullDownInProgress && scrollView.contentOffset.y <= 0.0 {
            placeHolderCell.frame = CGRect(x:0, y: -tableView.rowHeight, width: tableView.frame.size.width, height: tableView.rowHeight)
            placeHolderCell.label.text = -scrollViewContentOffSetY > tableView.rowHeight ?
                "Release to add item" : "Pull farther to add item"
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
        var val = (CGFloat(index) / CGFloat(itemCount)) * 0.6
        if itemCount == 0 {
            val = 0.0
        }
        return UIColor(red: 0.0, green: val, blue: 1.0, alpha: 1.0)
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.backgroundColor = colorForIndex(indexPath.row)
    }

}
