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
    
    @objc func notificationReceived(_ notification: Foundation.Notification) {
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
                NotificationCenter.default.removeObserver(NotificationListener2.sharedInstance)
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
                    
                    NotificationCenter.default.addObserver(NotificationListener2.sharedInstance,
                        selector: #selector(NotificationListener2.notificationReceived(_:)),
                        name: user.objectIdentifier().map { NSNotification.Name(rawValue: $0) },
                        object: nil)
                    
                    try! realm.write {
                        user.name = "new name"
                        user.notifyChange() //Notifies that there's a change on the object
                    }
                }
                
                afterEach {
                    try! realm.write {
                        let tasks = realm.objects(Task.self).toArray().filter { $0.id == id }
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
                    NotificationCenter.default.addObserver(NotificationListener2.sharedInstance,
                        selector: #selector(NotificationListener2.notificationReceived(_:)),
                        name: user.objectIdentifier().map { NSNotification.Name(rawValue: $0) },
                        object: nil)
                    user.name = "new name"
                    user.notifyChange() //Notifies that there's a change on the object
                }
                it("Should NOT have received a notification for the change") {
                    expect(NotificationListener2.sharedInstance.notificationReceived).to(beFalsy())
                }
            }
        }
        describe("primaryKeyValue()") {
            var value: Any?
            context("if the object does not have primary key") {
                beforeEach {
                    let dummy = Dummy()
                    value = dummy.primaryKeyValue()
                }
                it("should be nil") {
                    expect(value).to(beNil())
                }
            }
            context("if the object have primary key") {
                beforeEach {
                    let dummy = Task()
                    value = dummy.primaryKeyValue()
                }
                it("should be 0") {
                    expect(value as? Int) == 0
                }
            }
        }
        
        describe("hasSamePrimaryKeyValue(object:)") {
            var value: Bool!
            context("if both object don't have primary key") {
                beforeEach {
                    let dummy1 = Dummy()
                    let dummy2 = Dummy()
                    value = dummy1.hasSamePrimaryKeyValue(as: dummy2)
                }
                it("should return false") {
                    expect(value).to(beFalsy())
                }
            }
            context("if passed object does not have primary key") {
                beforeEach {
                    let dummy1 = Task()
                    let dummy2 = Dummy()
                    value = dummy1.hasSamePrimaryKeyValue(as: dummy2)
                }
                it("should return false") {
                    expect(value).to(beFalsy())
                }
            }
            context("if only the instance object does not have primary key") {
                beforeEach {
                    let dummy1 = Dummy()
                    let dummy2 = Task()
                    value = dummy1.hasSamePrimaryKeyValue(as: dummy2)
                }
                it("should return false") {
                    expect(value).to(beFalsy())
                }
            }
            context("if both objects have primary key") {
                context("when the primary keys match") {
                    beforeEach {
                        let dummy1 = Task()
                        let dummy2 = Task()
                        value = dummy1.hasSamePrimaryKeyValue(as: dummy2)
                    }
                    it("should return true") {
                        expect(value).to(beTruthy())
                    }
                }
                context("when primary keys do not match") {
                    beforeEach {
                        let dummy1 = Task()
                        let dummy2 = Task()
                        dummy2.id = 2
                        value = dummy1.hasSamePrimaryKeyValue(as: dummy2)
                    }
                    it("should return false") {
                        expect(value).to(beFalsy())
                    }
                }
            }
        }
    }
}
