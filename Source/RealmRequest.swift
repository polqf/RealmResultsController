//
//  RealmRequest.swift
//  redbooth-ios-sdk
//
//  Created by Isaac Roldan on 4/8/15.
//  Copyright © 2015 Redbooth Inc. All rights reserved.
//

import Foundation
import RealmSwift


public struct RealmRequest<T: Object> {
    var entityType: T.Type { return T.self }
    var predicate: NSPredicate = NSPredicate(value: true)
    var realm: Realm
    var sortDescriptors: [SortDescriptor] = []
    
    func execute() -> Results<T> {
        return  realm.objects(entityType).filter(predicate).sorted(sortDescriptors)
    }
}



