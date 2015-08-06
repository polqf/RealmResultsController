//
//  RealmLogger.swift
//  RealmResultsController
//
//  Created by Pol Quintana on 6/8/15.
//  Copyright © 2015 Redbooth. All rights reserved.
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

