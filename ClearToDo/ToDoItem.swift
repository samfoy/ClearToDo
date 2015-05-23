//
//  ToDoItem.swift
//  ClearToDo
//
//  Created by Samuel Painter on 5/21/15.
//  Copyright (c) 2015 Samuel Painter. All rights reserved.
//

import UIKit
import CoreData

class ToDoItem: NSManagedObject {
    
    @NSManaged var text: String
    
    @NSManaged var completed: Bool
    
    class func createInManagedObjectContext(moc: NSManagedObjectContext, text: String) -> ToDoItem {
        let item = NSEntityDescription.insertNewObjectForEntityForName("ToDoItem", inManagedObjectContext: moc) as! ToDoItem
        item.text = text
        item.completed = false
        return item
    }
    
}
