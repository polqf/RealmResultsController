//
//  RealmChange.swift
//  RealmResultsController
//
//  Created by Pol Quintana on 11/8/15.
//  Copyright © 2015 Redbooth. All rights reserved.
//

import Foundation
import RealmSwift

enum RealmAction {
    case Create
    case Update
    case Delete
}

class RealmChange {
    var type: Object.Type
    var primaryKey: AnyObject
    var action: RealmAction
    var mirror: Object?
    
    init<T:Object>(type: T.Type, primaryKey: AnyObject, action: RealmAction, mirror: Object?) {
        self.type = type
        self.primaryKey = primaryKey
        self.action = action
        self.mirror = mirror
    }
}