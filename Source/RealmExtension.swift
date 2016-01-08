//
//  RealmExtension.swift
//  redbooth-ios-sdk
//
//  Created by Isaac Roldan on 4/8/15.
//  Copyright © 2015 Redbooth Inc.
//

import Foundation
import RealmSwift

extension Realm {
    
    //MARK: Add
    
    /**
    Wrapper of realm.add()
    The adition to the realm works the same way as the original method.
    It will notify any active RealmResultsController of the addition.
    
    
    Original Realm Doc:
    Adds or updates an object to be persisted it in this Realm.
    
    When 'update' is 'true', the object must have a primary key. If no objects exist in
    the Realm instance with the same primary key value, the object is inserted. Otherwise,
    the existing object is updated with any changed values.
    
    When added, all linked (child) objects referenced by this object will also be
    added to the Realm if they are not already in it. If the object or any linked
    objects already belong to a different Realm an exception will be thrown. Use one
    of the `create` functions to insert a copy of a persisted object into a different
    Realm.
    
    The object to be added must be valid and cannot have been previously deleted
    from a Realm (i.e. `invalidated` must be false).
    
    - parameter object: Object to be added to this Realm.
    - parameter update: If true will try to update existing objects with the same primary key.
    
    */
    public func addNotified<N: Object>(object: N, update: Bool = false) {
        defer { add(object, update: update) }
        var primaryKey: String?
        primaryKey = (object as Object).dynamicType.primaryKey()
        guard let pKey = primaryKey,
            let primaryKeyValue = (object as Object).valueForKey(pKey) else {
                return
        }
        
        if let _ = objectForPrimaryKey((object as Object).dynamicType.self, key: primaryKeyValue) {
            RealmNotification.loggerForRealm(self).didUpdate(object)
            return
        }
        RealmNotification.loggerForRealm(self).didAdd(object)
    }
    
    /**
    Wrapper of realm.add([])
    The aditions to the realm works the same way as the original method.
    It will notify any active RealmResultsController of the additions.
    
    
    Original Realm Doc:
    Adds or updates objects in the given sequence to be persisted it in this Realm.
    
    - see: add(object:update:)
    
    - parameter objects: A sequence which contains objects to be added to this Realm.
    - parameter update: If true will try to update existing objects with the same primary key.

    */
    public func addNotified<S: SequenceType where S.Generator.Element: Object>(objects: S, update: Bool = false) {
        for object in objects {
            addNotified(object, update: update)
        }
    }

    /**
    Wrapper of realm.create()
    The creation to the realm works the same way as the original method.
    It will notify any active RealmResultsController of the creation.
    
    Original Realm Doc:
    Create an `Object` with the given value.
    
    Creates or updates an instance of this object and adds it to the `Realm` populating
    the object with the given value.
    
    When 'update' is 'true', the object must have a primary key. If no objects exist in
    the Realm instance with the same primary key value, the object is inserted. Otherwise,
    the existing object is updated with any changed values.
    
    
    - parameter type  The object type to create.
    - parameter value  The value used to populate the object. This can be any key/value coding compliant object, or a JSON dictionary such as those returned from the methods in NSJSONSerialization, or an Array with one object for each persisted property. An exception will be thrown if any required properties are not present and no default is set. When passing in an Array, all properties must be present, valid and in the same order as the properties defined in the model.
    - parameter update If true will try to update existing objects with the same primary key.
    
    - returns: The created object.
    */
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
    /**
    Wrapper of realm.delete()
    The deletion works the same way as the original Realm method.
    It will notify any active RealmResultsController of the deletion
    
    Original Realm Doc:
    Deletes the given object from this Realm.
    
    - parameter object: The object to be deleted.
    */
    public func deleteNotified(object: Object) {
        RealmNotification.loggerForRealm(self).didDelete(object)
        delete(object)
    }
    
    /**
    Wrapper of realm.delete()
    The deletion works the same way as the original Realm method.
    It will notify any active RealmResultsController of the deletion
    
    Deletes the given objects from this Realm.
    
    - parameter object: The objects to be deleted. This can be a `List<Object>`, `Results<Object>`,
    or any other enumerable SequenceType which generates Object.
    */
    public func deleteNotified<S: SequenceType where S.Generator.Element: Object>(objects: S) {
        for object in objects {
            deleteNotified(object)
        }
    }
 
    
    //MARK: Execute
    /**
    Execute a given RealmRequest in the current Realm (ignoring the realm in which the 
    Request was created)
    
    - parameter request RealmRequest to execute
    
    - returns Realm Results<T>
    */
    public func execute<T: Object>(request: RealmRequest<T>) -> Results<T> {
        return objects(request.entityType).filter(request.predicate).sorted(request.sortDescriptors)
    }
}

extension Results {
    
    /**
    Transform a Results<T> into an Array<T>
    
    - returns Array<T>
    */
    func toArray() -> [T] {
        var array = [T]()
        for result in self {
            array.append(result)
        }
        return array
    }
}
