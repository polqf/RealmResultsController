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
    
    @objc func notificationReceived(_ notification: Foundation.Notification) {
        array = notification.object as! [String : [RealmChange]]
    }
}

class NotificationObserver {
    
    var notificationReceived: Bool = false
    init() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "Task-123"), object: nil, queue: nil) { (notification) -> Void in
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
            context("from main thread") {
                beforeEach {
                    newLogger = RealmLogger(realm: realm)
                }
                it("Should have a valid realm and a notificationToken") {
                    expect(newLogger.realm) === realm
                    expect(newLogger.notificationToken).toNot(beNil())
                }
            }
            context("not from main thread") {
                var bgRealm: Realm!
                beforeEach {
                    let queue = DispatchQueue(label: "TESTBG", attributes: [])
                    queue.sync {
                        let configuration = Realm.Configuration(inMemoryIdentifier: "testingRealmBG")
                        bgRealm = try! Realm(configuration: configuration)
                        newLogger = RealmLogger(realm: bgRealm)
                    }
                }
                it("Should have a valid realm and a notificationToken") {
                    expect(newLogger.realm) === bgRealm
                    expect(newLogger.notificationToken).toNot(beNil())
                }
            }
        }
        
        describe("finishRealmTransaction()") {
            let newObject = RealmChange(type: Task.self, action: .add, mirror: nil)
            let updatedObject = RealmChange(type: Task.self, action: .update, mirror: nil)
            let deletedObject = RealmChange(type: Task.self, action: .delete, mirror: nil)
            context("from main thread") {
                beforeEach {
                    logger.cleanAll()
                    logger.temporary.append(newObject)
                    logger.temporary.append(updatedObject)
                    logger.temporary.append(deletedObject)
                    NotificationCenter.default.addObserver(NotificationListener.sharedInstance, selector: #selector(NotificationListener.notificationReceived), name: NSNotification.Name(rawValue: "realmChangesTest"), object: nil)
                    logger.finishRealmTransaction()
                }
                afterEach {
                    NotificationCenter.default.removeObserver(self)
                }
                it("Should have received a notification with a valid dictionary") {
                    let notificationArray = NotificationListener.sharedInstance.array
                    var createdObject: Bool = false
                    var updatedObject: Bool = false
                    var deletedObject: Bool = false
                    for object: RealmChange in notificationArray[realm.realmIdentifier]! {
                        if object.action == RealmAction.add { createdObject = true}
                        if object.action == RealmAction.update { updatedObject = true}
                        if object.action == RealmAction.delete { deletedObject = true}
                    }
                    expect(createdObject).to(beTruthy())
                    expect(updatedObject).to(beTruthy())
                    expect(deletedObject).to(beTruthy())
                }
            }
            
            context("not from main thread") {
                beforeEach {
                    var newLogger: RealmLogger!
                    let queue = DispatchQueue(label: "TESTBG", attributes: [])
                    queue.sync {
                        let configuration = Realm.Configuration(inMemoryIdentifier: "testingRealmBG")
                        let realm = try! Realm(configuration: configuration)
                        newLogger = RealmLogger(realm: realm)
                    }
                    newLogger.cleanAll()
                    newLogger.temporary.append(newObject)
                    newLogger.temporary.append(updatedObject)
                    newLogger.temporary.append(deletedObject)
                    NotificationCenter.default.addObserver(NotificationListener.sharedInstance, selector: #selector(NotificationListener.notificationReceived), name: NSNotification.Name(rawValue: "realmChangesTest"), object: nil)
                    newLogger.finishRealmTransaction()
                }
                afterEach {
                    NotificationCenter.default.removeObserver(self)
                }
                it("Should have received a notification with a valid dictionary") {
                    let notificationArray = NotificationListener.sharedInstance.array
                    var createdObject: Bool = false
                    var updatedObject: Bool = false
                    var deletedObject: Bool = false
                    for object: RealmChange in notificationArray[realm.realmIdentifier]! {
                        if object.action == RealmAction.add { createdObject = true}
                        if object.action == RealmAction.update { updatedObject = true}
                        if object.action == RealmAction.delete { deletedObject = true}
                    }
                    expect(createdObject).to(beTruthy())
                    expect(updatedObject).to(beTruthy())
                    expect(deletedObject).to(beTruthy())
                }
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
                expect(logger.temporary.first!.action).to(equal(RealmAction.add))
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
                expect(logger.temporary.first!.action).to(equal(RealmAction.update))
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
                expect(logger.temporary.first!.action).to(equal(RealmAction.delete))
            }
        }
        
        describe("finishRealmTransaction()") {
            let observer = NotificationObserver()
            var newObject: RealmChange!
            context("object without mirror") {
                beforeEach {
                    newObject = RealmChange(type: Task.self, action: .add, mirror: nil)
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
                    newObject = RealmChange(type: Task.self, action: .add, mirror: Dummy())
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
                    newObject = RealmChange(type: Task.self, action: .add, mirror: task)
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
