//
//  RealmExtension.swift
//  redbooth-ios-sdk
//
//  Created by Isaac Roldan on 4/8/15.
//  Copyright © 2015 Redbooth Inc. All rights reserved.
//

import Foundation
import RealmSwift

extension Realm {
    
    //MARK: Add
    
    public func addNotified<N: Object>(object: N, update: Bool = false) {
        defer { add(object, update: update) }
        
        guard let primaryKey = object.dynamicType.primaryKey() else { return }
        let primaryKeyValue = (object as Object).valueForKey(primaryKey)!
        
        if let _ = objectForPrimaryKey(object.dynamicType.self, key: primaryKeyValue) {
            RealmNotification.loggerForRealm(self).didUpdate(object)
            return
        }
        RealmNotification.loggerForRealm(self).didAdd(object)
    }
    
    public func addNotified<S: SequenceType where S.Generator.Element: Object>(objects: S, update: Bool = false) {
        for object in objects {
            addNotified(object, update: update)
        }
    }
    
    public func createNotified<T: Object>(type: T.Type, value: AnyObject = [:], var update: Bool = false) -> T? {
        let createBlock = {
            return self.create(type, value: value, update: update)
        }
        
        var create = true
        guard let primaryKey = T.primaryKey() else { return nil }
        guard let primaryKeyValue = value.valueForKey(primaryKey) else { return nil }
        
        if let _ = objectForPrimaryKey(type, key: primaryKeyValue) {
            create = false
            update = true
        }
        let createdObject = createBlock()
        
        if create {
            RealmNotification.loggerForRealm(self).didAdd(createdObject)
        }
        else {
            RealmNotification.loggerForRealm(self).didUpdate(createdObject)
        }
        return createdObject
    }
    
    
    //MARK: Delete
    
    public func deleteNotified(object: Object) {
        RealmNotification.loggerForRealm(self).didDelete(object)
        delete(object)
    }
    
    public func deleteNotified<S: SequenceType where S.Generator.Element: Object>(objects: S) {
        for object in objects {
            deleteNotified(object)
        }
    }
 
    
    //MARK: Execute
    
    public func execute<T: Object>(request: RealmRequest<T>) -> Results<T> {
        return objects(request.entityType).filter(request.predicate).sorted(request.sortDescriptors)
    }
}

extension Results {
    func toArray<T>(ofType: T.Type) -> [T] {
        var array = [T]()
        for result in self {
            if let result = result as? T {
                array.append(result)
            }
        }
        return array
    }
}


func getMirror<T: Object>(object: T) -> T {
    let newObject = object.dynamicType.init()
    let mirror = Mirror(reflecting: object)
    for c in mirror.children.enumerate() {
        let key = c.1.0!
        let value = (object as Object).valueForKey(key)
        guard let v = value else { continue }
        (newObject as Object).setValue(v, forKey: key)
    }
    return newObject
}

