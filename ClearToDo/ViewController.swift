
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
    
    var itemCount: Int {
        get {
            return toDoItems.count - 1
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        toDoItems.append(ToDoItem(text: "feed the cat"))
        toDoItems.append(ToDoItem(text: "buy eggs"))
        toDoItems.append(ToDoItem(text: "watch WWDC videos"))
        toDoItems.append(ToDoItem(text: "rule the Web"))
        toDoItems.append(ToDoItem(text: "buy a new iPhone"))
        toDoItems.append(ToDoItem(text: "darn holes in socks"))
        toDoItems.append(ToDoItem(text: "write this tutorial"))
        toDoItems.append(ToDoItem(text: "master Swift"))
        toDoItems.append(ToDoItem(text: "learn to draw"))
        toDoItems.append(ToDoItem(text: "get more exercise"))
        toDoItems.append(ToDoItem(text: "catch up with Mom"))
        toDoItems.append(ToDoItem(text: "get a hair cut"))
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
    
    // MARK: - Table view delegate
    
    func colorForIndex(index: Int) -> UIColor {
        let itemCount = toDoItems.count - 1
        let val = (CGFloat(index) / CGFloat(itemCount)) * 0.6
        return UIColor(red: 1.0, green: val, blue: 0.0, alpha: 1.0)
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        cell.backgroundColor = colorForIndex(indexPath.row)
    }

}
