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
    var dictionary: [String : AnyObject] = [:]
    
    @objc func notificationReceived(notification: NSNotification) {
        dictionary = notification.object as! [String : AnyObject]
    }
}

class RealmLoggerSpec: QuickSpec {
    override func spec() {
        var realm: Realm!
        var logger: RealmLogger!
        beforeSuite {
            RealmTestHelper.loadRealm()
            realm = try! Realm()
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
            let newObject = Task()
            let updatedObject = Task()
            let deletedObject = Task()
            beforeEach {
                logger.cleanAll()
                logger.temporaryAdded.append(newObject)
                logger.temporaryUpdated.append(updatedObject)
                logger.temporaryDeleted.append(deletedObject)
                NSNotificationCenter.defaultCenter().addObserver(NotificationListener.sharedInstance, selector: "notificationReceived:", name: "realmChanges", object: nil)
                logger.finishRealmTransaction()
            }
            afterEach {
                NSNotificationCenter.defaultCenter().removeObserver(self)
            }
            it("Should have received a notification with a valid dictionary") {
                let addedArray = NotificationListener.sharedInstance.dictionary["added"] as! [Task]
                let updatedArray = NotificationListener.sharedInstance.dictionary["updated"] as! [Task]
                let deletedArray = NotificationListener.sharedInstance.dictionary["deleted"] as! [Task]
                
                expect(addedArray.first!) === newObject
                expect(updatedArray.first!) === updatedObject
                expect(deletedArray.first!) === deletedObject
            }

        }
        
        describe("didAdd<T: Object>(object: T)") {
            let newObject = Task()
            beforeEach {
                newObject.name = "New Task"
                logger.didAdd(newObject)
            }
            it("Should be added to the temporaryAdded array") {
                expect(logger.temporaryAdded.count).to(equal(1))
                expect(logger.temporaryAdded.first!) === newObject
            }
        }
        
        describe("didUpdate<T: Object>(object: T)") {
            let updatedObject = Task()
            beforeEach {
                updatedObject.name = "Updated Task"
                logger.didUpdate(updatedObject)
            }
            it("Should be added to the temporaryAdded array") {
                expect(logger.temporaryUpdated.count).to(equal(1))
                expect(logger.temporaryUpdated.first!) === updatedObject
            }
        }
        
        describe("didDelete<T: Object>(object: T)") {
            let deletedObject = Task()
            beforeEach {
                deletedObject.name = "Deleted Task"
                logger.didDelete(deletedObject)
            }
            it("Should be added to the temporaryAdded array") {
                expect(logger.temporaryDeleted.count).to(equal(1))
                expect(logger.temporaryDeleted.first!) === deletedObject
            }
        }
        
        describe("finishRealmTransaction()") {
            let newObject = Task()
            beforeEach {
                logger.temporaryAdded.append(newObject)
                logger.temporaryUpdated.append(newObject)
                logger.temporaryDeleted.append(newObject)
                logger.cleanAll()
            }
            it("Should remove all the objects in each temporary array") {
                expect(logger.temporaryDeleted.count).to(equal(0))
                expect(logger.temporaryUpdated.count).to(equal(0))
                expect(logger.temporaryAdded.count).to(equal(0))
            }
        }

    }
}