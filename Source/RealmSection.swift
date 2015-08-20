//
//  RealmSection.swift
//  RealmResultsController
//
//  Created by Isaac Roldan on 7/8/15.
//  Copyright © 2015 Redbooth.
//

import Foundation
import RealmSwift


public struct RealmSection<U> {
    var objects: [U]?
    var keyPath: String
}

class Section<T: Object> : NSObject {
    var objects: NSMutableArray = []
    var keyPath: String = ""
    var sortDescriptors: [NSSortDescriptor] = []
    var allObjects: [T] {
        return objects.map {$0 as! T}
    }
    
    //MARK: Initializer
    
    required init(keyPath: String, sortDescriptors: [NSSortDescriptor]) {
        self.keyPath = keyPath
        self.sortDescriptors = sortDescriptors
    }
    
    //MARK: Actions
    
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
    
    //MARK: Outdated objects
    
    func deleteOutdatedObject(object: T) -> Int {
        let primaryKey = T.primaryKey()!
        let primaryKeyValue = (object as Object).valueForKey(primaryKey)!
        let objectToDelete: T? = objectForPrimaryKey(primaryKeyValue)
        if let object = objectToDelete {
            return delete(object)
        }
        return -1
    }
    
    func indexForOutdatedObject(object: T) -> Int {
        let primaryKey = T.primaryKey()!
        let primaryKeyValue = (object as Object).valueForKey(primaryKey)!
        let objectToDelete: T? = objectForPrimaryKey(primaryKeyValue)
        if let obj = objectToDelete {
            return objects.indexOfObject(obj)
        }
        return -1
    }
    
    //MARK: Helpers
    
    func objectForPrimaryKey(value: AnyObject) -> T? {
        for object in objects {
            let primaryKey = T.primaryKey()!
            let primaryKeyValue = object.valueForKey(primaryKey)!
            if primaryKeyValue.isEqual(value){
                return (object as? T)
            }
        }
        return nil
    }

}