//
//  ToDoItem.swift
//  ClearToDo
//
//  Created by Samuel Painter on 5/21/15.
//  Copyright (c) 2015 Samuel Painter. All rights reserved.
//

import UIKit

class ToDoItem: NSObject {
    
    var text: String
    
    var completed: Bool
    
    init(text: String) {
        self.text = text
        self.completed = false
    }   
}
