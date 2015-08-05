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
    
    func addNotified<T: Object>(object: T, var update: Bool = false) {
        defer { add(object, update: update) }
        
        guard let primaryKey = object.dynamicType.primaryKey() else { return } // Return if it does not have primary key
        guard let primaryKeyValue = (object as Object).valueForKey(primaryKey) else { return }
        
        if let _ = objectForPrimaryKey(object.dynamicType, key: primaryKeyValue) {
            RealmNotification.loggerForRealm(self).didUpdate(object)
            return
        }
        update = false
        RealmNotification.loggerForRealm(self).didAdd(object)
    }
    
    public func addNotified<S: SequenceType where S.Generator.Element: Object>(objects: S, update: Bool = false) {
        for object in objects {
            addNotified(object, update: update)
        }
    }
    
    public func createNotified<T: Object>(type: T.Type, value: AnyObject = [:], var update: Bool = false) -> T {
        let createBlock = {
            return self.create(type, value: value, update: update)
        }
        
        var create = true
        guard let primaryKey = T.primaryKey() else { return createBlock() } // Return if it does not have primary key
        guard let primaryKeyValue = value[primaryKey] else { return createBlock() }
        guard let pk = primaryKeyValue else { return createBlock() }
        
        if let _ = objectForPrimaryKey(type, key: pk) {
            create = false
            update = false
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
    
    public func deleteNotified(object: Object) {
        delete(object)
        RealmNotification.loggerForRealm(self).didDelete(object)
    }
    
    public func deleteNotified<S: SequenceType where S.Generator.Element: Object>(objects: S) {
        for object in objects {
            deleteNotified(object)
        }
    }
    
    public func deleteAllNotified() {
        deleteAll()
//        RealmNotification.didRemoveAllObjects()
    }
    
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
