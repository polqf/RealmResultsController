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
    public var objects: [U]?
    public var keyPath: String
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
        insert(object)
        sort()
        return objects.indexOfObject(object)
    }
    
    func insert(object: T) {
        objects.addObject(object)
    }
    
    func sort() {
        objects.sortUsingDescriptors(sortDescriptors)
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
        if let object = outdatedObject(object) {
            return delete(object)
        }
        return -1
    }
    
    func outdatedObject(object: T) -> T? {
        guard let primaryKey = T.primaryKey(),
            let primaryKeyValue = (object as Object).valueForKey(primaryKey) else { return nil }
        return objectForPrimaryKey(primaryKeyValue)
    }
    
    func indexForOutdatedObject(object: T) -> Int {
        let objectToDelete: T? = outdatedObject(object)
        if let obj = objectToDelete {
            return objects.indexOfObject(obj)
        }
        return -1
    }
    
    //MARK: Helpers
    
    func objectForPrimaryKey(value: AnyObject) -> T? {
        for object in objects {
            guard let primaryKey = T.primaryKey(),
                let primaryKeyValue = object.valueForKey(primaryKey) else {
                    continue
            }
            if primaryKeyValue.isEqual(value){
                return (object as? T)
            }
        }
        return nil
    }

}