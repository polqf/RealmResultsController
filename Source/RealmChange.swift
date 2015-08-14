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
    var action: RealmAction
    var mirror: Object?
    
    init<T:Object>(type: T.Type, action: RealmAction, mirror: Object?) {
        self.type = type
        self.action = action
        self.mirror = mirror
    }
}