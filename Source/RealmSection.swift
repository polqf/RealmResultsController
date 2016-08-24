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
    
    func insertSorted(_ object: T) -> Int {
        insert(object)
        
        Threading.executeOnMainThread(true) {
            self.sort()
        }
        
        return objects.index(of: object)
    }
    
    func insert(_ object: T) {
        objects.add(object)
    }
    
    func sort() {
        objects.sort(using: sortDescriptors)
    }
    
    func delete(_ object: T) -> Int? {
        let index = objects.index(of: object)
        if index < objects.count {
            objects.remove(object)
            return index
        }
        return nil
    }
    
    //MARK: Outdated objects

    func deleteOutdatedObject(_ object: T) -> Int? {
        if let object = outdatedObject(object) {
            return delete(object)
        }
        return nil
    }
    
    func outdatedObject(_ object: T) -> T? {
        guard let primaryKey = T.primaryKey(),
            let primaryKeyValue = (object as RealmSwift.Object).value(forKey: primaryKey) else { return nil }
        return objectForPrimaryKey(primaryKeyValue)
    }
    
    func indexForOutdatedObject(_ object: T) -> Int? {
        let objectToDelete: T? = outdatedObject(object)
        if let obj = objectToDelete {
            return objects.index(of: obj)
        }
        return nil
    }

    //MARK: Helpers
    
    func objectForPrimaryKey(_ value: Any) -> T? {
        for object in objects {
            guard let primaryKey = T.primaryKey() else { continue }
            var primaryKeyValue: Any?
            Threading.executeOnMainThread(true) {
                primaryKeyValue = (object as AnyObject).value(forKey: primaryKey)
            }
            if (value as? NSObject)?.isEqual((primaryKeyValue as? NSObject)) == true {
                return (object as? T)
            }
        }
        return nil
    }

}
