//
//  RealmSection.swift
//  RealmResultsController
//
//  Created by Isaac Roldan on 7/8/15.
//  Copyright © 2015 Redbooth. All rights reserved.
//

import Foundation
import RealmSwift


class Section<T: Object> : NSObject {
    var objects: NSMutableArray = []
    public var keyPath: String = ""
    public var allObjects: NSArray {
        return objects.copy() as! NSArray
    }
    
    var sortDescriptors: [NSSortDescriptor] = []
    
    required init(keyPath: String, sortDescriptors: [NSSortDescriptor]) {
        self.keyPath = keyPath
        self.sortDescriptors = sortDescriptors
    }
    
    func insertSorted(object: T) -> Int {
        objects.addObject(object)
        objects.sortUsingDescriptors(sortDescriptors)
        return objects.indexOfObject(object)
    }
    
    func delete(object: T) -> Int {
        let index = objects.indexOfObject(object)
        if index < objects.count {
            objects.removeObject(object)
            return index
        }
        return -1
    }
    
    func deleteOutdatedObject(object: T) -> Int {
        let primaryKey = T.primaryKey()!
        let primaryKeyValue = (object as Object).valueForKey(primaryKey)!
        var objectToDelete: T?
        for sectionObject in objects{
            let value = sectionObject.valueForKey(primaryKey)!
            if value.isEqual(primaryKeyValue) {
                objectToDelete = sectionObject as? T
                break
            }
        }
        if let object = objectToDelete {
            return delete(object)
        }
        return -1
    }
}