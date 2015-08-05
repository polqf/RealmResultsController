//
//  RealmNotification.swift
//  redbooth-ios-sdk
//
//  Created by Pol Quintana on 4/8/15.
//  Copyright © 2015 Redbooth Inc. All rights reserved.
//

import Foundation
import RealmSwift

class RealmLogger {
    var realm: Realm
    var temporaryAdded: [Object] = []
    var temporaryDeleted: [Object] = []
    var temporaryUpdated: [Object] = []
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
        let dictionary = ["added": self.temporaryAdded, "deleted": self.temporaryDeleted, "updated": self.temporaryUpdated]
        NSNotificationCenter.defaultCenter().postNotificationName("realmChanges", object: dictionary)
        cleanAll()
    }
    
    func didAdd<T: Object>(object: T) {
        temporaryAdded.append(object)
    }
    
    func didUpdate<T: Object>(object: T) {
        temporaryUpdated.append(object)
    }
    
    func didDelete<T: Object>(object: T) {
        temporaryDeleted.append(object)
    }
    
    func cleanAll() {
        temporaryAdded.removeAll()
        temporaryDeleted.removeAll()
        temporaryUpdated.removeAll()
    }
}

class RealmNotification {
    
    static let sharedInstance = RealmNotification()
    var loggers: [RealmLogger] = []
    
    static func loggerForRealm(realm: Realm) -> RealmLogger {
        let logger = RealmNotification.sharedInstance.loggers.filter {$0.realm == realm}
        if let log = logger.first {
            return log
        }
        let newLogger = RealmLogger(realm: realm)
        RealmNotification.sharedInstance.loggers.append(newLogger)
        return newLogger
    }
}