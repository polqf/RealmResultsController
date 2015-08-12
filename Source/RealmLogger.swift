//
//  RealmLogger.swift
//  RealmResultsController
//
//  Created by Pol Quintana on 6/8/15.
//  Copyright © 2015 Redbooth. All rights reserved.
//

import Foundation
import RealmSwift


func getMirror<T: Object>(object: T) -> T {
    let newObject = object.dynamicType.init()
    let mirror = Mirror(reflecting: object)
    for c in mirror.children.enumerate() {
        let key = c.1.0
        guard let k = key else { continue }
        let value = (object as Object).valueForKey(k)
        guard let v = value else { continue }
//        print("🎄Setting \(k) to \(value)")
        (newObject as Object).setValue(v, forKey: k)
    }
    return newObject
}
//
//extension Object {
//    func getMirror() -> Object {
//        let object = self.dynamicType.init()
//        let mirror = Mirror(reflecting: self)
//        for c in mirror.children.enumerate() {
//            let key = c.1.0
//            print("🎄Setting \(c)")
//            let value = c.1.1 as! AnyObject
//            guard let k = key else { continue }
//            (object as Object).setValue(value, forKey: k)
//        }
//        return object
//    }
//}

class RealmLogger {
    var realm: Realm
    var temporary: [RealmChange] = []
    var notificationToken: NotificationToken?
    
    init(realm: Realm) {
        self.realm = realm
        self.notificationToken = self.realm.addNotificationBlock { (notification, realm) -> Void in
            if notification == .DidChange {
                self.finishRealmTransaction()
            }
        }
    }
    
    func finishRealmTransaction() {
        let name = realm.path.hasSuffix("testingRealm") ? "realmChangesTest" : "realmChanges"
        NSNotificationCenter.defaultCenter().postNotificationName(name, object: temporary)
        cleanAll()
    }
    
    func didAdd<T: Object>(object: T) {
        addObject(object, action: .Create)
    }
    
    func didUpdate<T: Object>(object: T) {
        addObject(object, action: .Update)
    }
    
    func didDelete<T: Object>(object: T) {
        addObject(object, action: .Delete)
    }
    
    func addObject<T: Object>(object: T, action: RealmAction) {
        let primaryKey = object.dynamicType.primaryKey()!
        let primaryKeyValue = (object as Object).valueForKey(primaryKey)
        let realmChange = RealmChange(type: object.dynamicType, primaryKey: primaryKeyValue!, action: action, mirror: getMirror(object))
        temporary.append(realmChange)
    }
    
    func cleanAll() {
        temporary.removeAll()
    }
    
}

