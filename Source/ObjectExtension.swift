//
//  ObjectExtension.swift
//  RealmResultsController
//
//  Created by Pol Quintana on 2/9/15.
//  Copyright © 2015 Redbooth. All rights reserved.
//

import Foundation
import RealmSwift

extension Object {
    
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
        RealmNotification.loggerForRealm(r).didUpdate(self)
    }

    /**
    Gives the object string identifier.
    Commonly used when posting individual notifications
    
    Structure: ObjectType-PrimaryKeyValue
    
    - returns: The identifier as String
    */
    public func objectIdentifier() -> String? {
        guard let primaryKey = self.dynamicType.primaryKey() else { return nil }
        let primaryKeyValue = String((self as Object).valueForKey(primaryKey)!)
        return String(self.dynamicType) + "-" + primaryKeyValue
    }
}