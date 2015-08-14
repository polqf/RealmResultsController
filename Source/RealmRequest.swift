//
//  RealmRequest.swift
//  redbooth-ios-sdk
//
//  Created by Isaac Roldan on 4/8/15.
//  Copyright © 2015 Redbooth Inc.
//

import Foundation
import RealmSwift


/**
Struct that encapsulates a request to a realm including:
- The entity to fetch
- The predicate to filter with
- The SortDescriptors to sort the results
- The Realm in which the request should be executed

*/
public struct RealmRequest<T: Object> {
    var entityType: T.Type { return T.self }
    var predicate: NSPredicate = NSPredicate(value: true)
    var realm: Realm
    var sortDescriptors: [SortDescriptor] = []
    
    func execute() -> Results<T> {
        return  realm.objects(entityType).filter(predicate).sorted(sortDescriptors)
    }
}