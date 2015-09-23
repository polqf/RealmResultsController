//
//  RealmObjectSpec.swift
//  RealmResultsController
//
//  Created by Pol Quintana on 22/9/15.
//  Copyright © 2015 Redbooth. All rights reserved.
//

import Foundation
import Quick
import Nimble
import RealmSwift

@testable import RealmResultsController

class NotificationListener2 {
    static let sharedInstance = NotificationListener2()
    var notificationReceived: Bool = false
    
    @objc func notificationReceived(notification: NSNotification) {
        notificationReceived = true
    }
}

class RealmObjectSpec: QuickSpec {
    
    override func spec() {
        var realm: Realm!
        beforeSuite {
            RealmTestHelper.loadRealm()
            realm = try! Realm()
        }
        describe("notifyChange()") {
            afterEach {
                NSNotificationCenter.defaultCenter().removeObserver(NotificationListener2.sharedInstance)
                NotificationListener2.sharedInstance.notificationReceived = false
            }
            context("With valid realm") {
                let id = 22222222222222
                beforeEach {
                    let user = Task()
                    try! realm.write {
                        user.id = id
                        user.name = "old name"
                        realm.addNotified(user, update: true)
                    }
                    
                    NSNotificationCenter.defaultCenter().addObserver(NotificationListener2.sharedInstance,
                        selector: "notificationReceived:",
                        name: user.objectIdentifier(),
                        object: nil)
                    
                    try! realm.write {
                        user.name = "new name"
                        user.notifyChange() //Notifies that there's a change on the object
                    }
                }
                
                afterEach {
                    try! realm.write {
                        let tasks = realm.objects(Task).toArray().filter { $0.id == id }
                        realm.delete(tasks.first!)
                    }
                }
                it("Should have received a notification for the change") {
                    expect(NotificationListener2.sharedInstance.notificationReceived).to(beTruthy())
                }
            }
            context("With invalid realm") {
                beforeEach {
                    let user = Task()
                    NSNotificationCenter.defaultCenter().addObserver(NotificationListener2.sharedInstance,
                        selector: "notificationReceived:",
                        name: user.objectIdentifier(),
                        object: nil)
                    user.name = "new name"
                    user.notifyChange() //Notifies that there's a change on the object
                }
                it("Should NOT have received a notification for the change") {
                    expect(NotificationListener2.sharedInstance.notificationReceived).to(beFalsy())
                }
            }
        }

    }
}
