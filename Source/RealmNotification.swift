//
//  RealmNotification.swift
//  redbooth-ios-sdk
//
//  Created by Pol Quintana on 4/8/15.
//  Copyright © 2015 Redbooth Inc.
//

import Foundation
import RealmSwift

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