//
//  RealmLoggerTests.swift
//  RealmResultsController
//
//  Created by Pol Quintana on 6/8/15.
//  Copyright © 2015 Redbooth.
//

import Foundation
import Quick
import Nimble
import RealmSwift

@testable import RealmResultsController

class NotificationListener {
    static let sharedInstance = NotificationListener()
    var array: [String : [RealmChange]] = [:]
    
    @objc func notificationReceived(notification: NSNotification) {
        array = notification.object as! [String : [RealmChange]]
    }
}

class NotificationObserver {
    
    var notificationReceived: Bool = false
    init() {
        NSNotificationCenter.defaultCenter().addObserverForName("Task-123", object: nil, queue: nil) { (notification) -> Void in
            self.notificationReceived = true
        }
    }
}

class RealmLoggerSpec: QuickSpec {
    override func spec() {
        var realm: Realm!
        var logger: RealmLogger!
        beforeSuite {
            let configuration = Realm.Configuration(inMemoryIdentifier: "testingRealm")
            realm = try! Realm(configuration: configuration)
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
            let newObject = RealmChange(type: Task.self, action: .Create, mirror: nil)
            let updatedObject = RealmChange(type: Task.self, action: .Update, mirror: nil)
            let deletedObject = RealmChange(type: Task.self, action: .Delete, mirror: nil)
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
                for object: RealmChange in notificationArray[realm.path]! {
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
            var newObject: Task!
            beforeEach {
                newObject = Task()
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
            var updatedObject: Task!
            beforeEach {
                updatedObject = Task()
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
            var deletedObject: Task!
            beforeEach {
                deletedObject = Task()
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
            let observer = NotificationObserver()
            var newObject: RealmChange!
            context("object without mirror") {
                beforeEach {
                    newObject = RealmChange(type: Task.self, action: .Create, mirror: nil)
                    logger.cleanAll()
                    logger.temporary.append(newObject)
                    logger.finishRealmTransaction()
                    logger.cleanAll()
                }
                it("Should remove all the objects in each temporary array") {
                    expect(logger.temporary.count).to(equal(0))
                }
                it("doesn;t send notification") {
                    expect(observer.notificationReceived).to(beFalsy())
                }
            }
            
            context("object with mirror without primaryKey") {
                beforeEach {
                    newObject = RealmChange(type: Task.self, action: .Create, mirror: Dummy())
                    logger.cleanAll()
                    logger.temporary.append(newObject)
                    logger.finishRealmTransaction()
                    logger.cleanAll()
                }
                it("Should remove all the objects in each temporary array") {
                    expect(logger.temporary.count).to(equal(0))
                }
                it("doesn;t send notification") {
                    expect(observer.notificationReceived).to(beFalsy())
                }
            }
            
            context("object with mirror and primaryKey") {
                beforeEach {
                    let task = Task()
                    task.id = 123
                    newObject = RealmChange(type: Task.self, action: .Create, mirror: task)
                    logger.cleanAll()
                    logger.temporary.append(newObject)
                    logger.finishRealmTransaction()
                    logger.cleanAll()
                }
                it("Should remove all the objects in each temporary array") {
                    expect(logger.temporary.count).to(equal(0))
                }
                it("doesn;t send notification") {
                    expect(observer.notificationReceived).to(beTruthy())
                }
            }
        }
    }
}