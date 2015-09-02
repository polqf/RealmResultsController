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
    Gives the object string identifier.
    Commonly used when posting individual notifications
    
    Structure: ObjectType-PrimaryKey
    
    :returns: The identifier as String
    */
    func objectIdentifier() -> String? {
        guard let primaryKey = self.dynamicType.primaryKey() else { return nil }
        let primaryKeyValue = String((self as Object).valueForKey(primaryKey)!)
        return String(self.dynamicType) + "-" + primaryKeyValue
    }
}