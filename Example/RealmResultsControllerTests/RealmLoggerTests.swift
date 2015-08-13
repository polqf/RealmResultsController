//
//  RealmLoggerTests.swift
//  RealmResultsController
//
//  Created by Pol Quintana on 6/8/15.
//  Copyright © 2015 Redbooth. All rights reserved.
//

import Foundation
import Quick
import Nimble
import RealmSwift

@testable import RealmResultsController

class NotificationListener {
    static let sharedInstance = NotificationListener()
    var array: [RealmChange] = []
    
    @objc func notificationReceived(notification: NSNotification) {
        array = notification.object as! [RealmChange]
    }
}

class RealmLoggerSpec: QuickSpec {
    override func spec() {
        var realm: Realm!
        var logger: RealmLogger!
        beforeSuite {
            realm = try! Realm(inMemoryIdentifier: "testingRealm")
            logger = RealmLogger(realm: realm)
        }
        
        describe("init(realm:)") {
            var newLogger: RealmLogger!
            beforeEach {
                newLogger = RealmLogger(realm: realm)
            }
            it("Should have a valid realm and a notificationToken") {
                expect(newLogger.realm) === realm
                expect(newLogger.notificationToken).toNot(beNil())
            }
        }
        
        describe("finishRealmTransaction()") {
            let newObject = RealmChange(type: Task.self, primaryKey: "", action: .Create, mirror: nil)
            let updatedObject = RealmChange(type: Task.self, primaryKey: "", action: .Update, mirror: nil)
            let deletedObject = RealmChange(type: Task.self, primaryKey: "", action: .Delete, mirror: nil)
            beforeEach {
                logger.cleanAll()
                logger.temporary.append(newObject)
                logger.temporary.append(updatedObject)
                logger.temporary.append(deletedObject)
                NSNotificationCenter.defaultCenter().addObserver(NotificationListener.sharedInstance, selector: "notificationReceived:", name: "realmChangesTest", object: nil)
                logger.finishRealmTransaction()
            }
            afterEach {
                NSNotificationCenter.defaultCenter().removeObserver(self)
            }
            it("Should have received a notification with a valid dictionary") {
                let notificationArray = NotificationListener.sharedInstance.array
                var createdObject: Bool = false
                var updatedObject: Bool = false
                var deletedObject: Bool = false
                for object: RealmChange in notificationArray {
                    if object.action == RealmAction.Create { createdObject = true}
                    if object.action == RealmAction.Update { updatedObject = true}
                    if object.action == RealmAction.Delete { deletedObject = true}
                }
                expect(createdObject).to(beTruthy())
                expect(updatedObject).to(beTruthy())
                expect(deletedObject).to(beTruthy())
            }

        }
        
        describe("didAdd<T: Object>(object: T)") {
            let newObject = Task()
            beforeEach {
                logger.cleanAll()
                newObject.name = "New Task"
                logger.didAdd(newObject)
            }
            afterEach {
                logger.cleanAll()
            }
            it("Should be added to the temporaryAdded array") {
                expect(logger.temporary.count).to(equal(1))
                expect(logger.temporary.first!.action).to(equal(RealmAction.Create))
            }
        }
        
        describe("didUpdate<T: Object>(object: T)") {
            let updatedObject = Task()
            beforeEach {
                logger.cleanAll()
                updatedObject.name = "Updated Task"
                logger.didUpdate(updatedObject)
            }
            afterEach {
                logger.cleanAll()
            }
            it("Should be added to the temporaryAdded array") {
                expect(logger.temporary.count).to(equal(1))
                expect(logger.temporary.first!.action).to(equal(RealmAction.Update))
            }
        }
        
        describe("didDelete<T: Object>(object: T)") {
            let deletedObject = Task()
            beforeEach {
                logger.cleanAll()
                deletedObject.name = "Deleted Task"
                logger.didDelete(deletedObject)
            }
            afterEach {
                logger.cleanAll()
            }
            it("Should be added to the temporaryAdded array") {
                expect(logger.temporary.count).to(equal(1))
                expect(logger.temporary.first!.action).to(equal(RealmAction.Delete))
            }
        }
        
        describe("finishRealmTransaction()") {
            let newObject = RealmChange(type: Task.self, primaryKey: "", action: .Create, mirror: nil)
            beforeEach {
                logger.cleanAll()
                logger.temporary.append(newObject)
                logger.cleanAll()
            }
            it("Should remove all the objects in each temporary array") {
                expect(logger.temporary.count).to(equal(0))
            }
        }

    }
}