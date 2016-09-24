//
//  ObjectExtension.swift
//  RealmResultsController
//
//  Created by Pol Quintana on 2/9/15.
//  Copyright © 2015 Redbooth. All rights reserved.
//

import Foundation
import RealmSwift

extension RealmSwift.Object {
    
    /**
    Use this func to notify the RRC of changes done in a specific object.
    Useful when you modify an object inside a write transaction but without doing an `add` or `create` action like:
    
    ```
    let user = User()
    user.name = "old name"
    
    realm.write {
    realm.add(user)
    }
    
    realm.write {
    user.name = "new name"
    user.notifyChange()
    }
    ```
    */
    public func notifyChange() {
        guard let r = self.realm else { return }
        RealmNotification.logger(for: r).didUpdate(self)
    }

    /**
    Gives the object string identifier.
    Commonly used when posting individual notifications
    
    Structure: ObjectType-PrimaryKeyValue
    
    - returns: The identifier as String
    */
    public func objectIdentifier() -> String? {
        guard let primaryKey = type(of: self).primaryKey(),
            let primaryKeyValue = (self as RealmSwift.Object).value(forKey: primaryKey) else { return nil }
        return "\(type(of: self))-\(primaryKeyValue)"
    }
    
    
    /**
     Create a mirror of an object <T: Object>.
     This mirror is not added to any Raelm so it is
     "thread safe" as long as you don't try to access
     any relationship from a background thread
     
     If you want safely access relationships, you have to override
     this method in your subclass for creating mirrors for relationships on your own,
     like the code below:
     
     extension Product {
        override func getMirror() -> Product {
            let clone = super.getMirror() as! Product
            clone.category = self.category?.getMirror() as? Category
            return clone
        }
     }
     
     - parameter object Original object (T) to mirror
     
     - returns a copy of the original object (T) but not included in any realm
     */
    public func getMirror() -> Self {
        let newObject = type(of: self).init()
        let mirror = Mirror(reflecting: self)
        for c in mirror.children.enumerated() {
            guard let key = c.1.0, !key.hasSuffix(".storage") else { continue }
            let value = self.value(forKey: key)
            guard let v = value else { continue }
            (newObject as RealmSwift.Object).setValue(v, forKey: key)
        }
        return newObject
    }
    
    /**
     Returns the value of the its primary key.
     If the type does not have primaryKey set, it returns nil.
     
     The access to the value of the primary key is done in the main thread, and sync,
     to avoid Realm being accessed from incorrect threads.
     
     - returns  the primary key value as AnyObject
     */
    public func primaryKeyValue() -> Any? {
        guard let primaryKey = type(of: (self as Object)).primaryKey() else { return nil }
        var primaryKeyValue: Any?
        Threading.executeOnMainThread(true) {
            primaryKeyValue = self.value(forKey: primaryKey)
        }
        return primaryKeyValue
    }
    
    /**
     Returns true whether both objects have the same primary key values.
     If they don't have primary key, it returns false
     
     - parameter object     Object to be compared with the current instance
     
     - returns Bool         true if they have the same primary key value
    */
    func hasSamePrimaryKeyValue<T: RealmSwift.Object>(as object: T) -> Bool {
        guard let objectValue = object.primaryKeyValue() as? NSObject, let selfValue = primaryKeyValue() as? NSObject else {
            return false
        }

        return objectValue.isEqual(selfValue)
    }
}
