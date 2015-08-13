//
//  RealmResultsControllerTests.swift
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

class RealmResultsDelegate: RealmResultsControllerDelegate {
    static let sharedInstance = RealmResultsDelegate()
    var oldIndexPath: NSIndexPath?
    var newIndexPath: NSIndexPath?
    var sectionIndex: Int = 0
    var changeType: RealmResultsChangeType = .Move
    var object: Task?
    var section: RealmSection<Task>!
    
    func willChangeResults(controller: AnyObject) {}
    
    func didChangeObject<U>(object: U, controller: AnyObject, atIndexPath: NSIndexPath, newIndexPath: NSIndexPath, changeType: RealmResultsChangeType) {
        self.object = object as? Task
        self.oldIndexPath = atIndexPath
        self.newIndexPath = newIndexPath
        self.changeType = changeType
    }
    
    func didChangeSection<U>(section: RealmSection<U>, controller: AnyObject, index: Int, changeType: RealmResultsChangeType) {
        self.section = section as! RealmSection<Task>
        self.sectionIndex = index
        self.changeType = changeType
    }

    
    func didChangeResults(controller: AnyObject) {}
}

class RealmResultsControllerSpec: QuickSpec {

    override func spec() {
        var realm: Realm!
        var request: RealmRequest<Task>!
        var RRC: RealmResultsController<Task, Task>!
        let RRCDelegate = RealmResultsDelegate.sharedInstance
        
        beforeSuite {
            RealmTestHelper.loadRealm()
            realm = try! Realm()
            let predicate = NSPredicate(value: true)
            request = RealmRequest<Task>(predicate: predicate, realm: realm, sortDescriptors: [])
            RRC = RealmResultsController<Task, Task>(forTESTRequest: request, sectionKeyPath: nil) { $0 }
            RRC.delegate = RRCDelegate
        }

        afterSuite {
            RRC.delegate = nil
            RRC = nil
        }
        
        describe("init(request:mapper:)") {
            var createdRRC: RealmResultsController<Task, Task>!
            
            beforeEach {
                createdRRC = RealmResultsController<Task, Task>(request: request, sectionKeyPath: nil) { $0 }
            }
            it("Should have initialized a RRC") {
                expect(createdRRC).toNot(beNil())
                expect(createdRRC.request).toNot(beNil())
                expect(createdRRC.mapper).toNot(beNil())
                expect(createdRRC.cache.delegate).toNot(beNil())
                expect(createdRRC.cache.defaultKeyPathValue).to(equal("default"))
            }
            
            it("try to execute a block in main thread from a background queue") {
                let queue = dispatch_queue_create("lock", DISPATCH_QUEUE_SERIAL)
                dispatch_async(queue) {
                    RRC.executeOnMainThread { }
                }
            }
            
            context("using valid mapper") {
                var createdRRC: RealmResultsController<TaskModel, Task>!
                var sameType: Bool = false
                beforeEach {
                    let request = RealmRequest<TaskModel>(predicate: NSPredicate(value: true), realm: realm, sortDescriptors: [])
                    createdRRC = RealmResultsController<TaskModel, Task>(request: request, sectionKeyPath: nil, mapper: Task.map)
                    createdRRC.performFetch()
                    let object = createdRRC.objectAt(NSIndexPath(forRow: 0, inSection: 0))
                    sameType = object.isKindOfClass(Task)
                }
                it("returns mapped object") {
                    expect(sameType).to(beTruthy())
                }
            }
        }
        
        describe("numberOfSections") {
            beforeEach {
                RRC.performFetch()
            }
            it("has 1 section") {
                expect(RRC.numberOfSections) == 1
            }
        }
        
        describe("numberOfObjectsAt:") {
            var total: Int = 0
            beforeEach {
                RRC.performFetch()
                total = RRC.numberOfObjectsAt(0)
            }
            it("has 1001 objects in the first section") {
                expect(total) == 1001
            }
        }
        
        describe("objectAt:") {
            var object: Task?
            var fetchedObject: Task?
            beforeEach {
                RRC.performFetch()
                fetchedObject = RRC.cache.sections[0].objects[5] as! Task
                object = RRC.objectAt(NSIndexPath(forRow: 5, inSection: 0))
            }
            it("returns the correct object") {
                expect(object) == fetchedObject
            }
        }
        
        describe("performFetch()") {
            var requestResult: [RealmSection<Task>]!
            
            beforeEach {
                requestResult = RRC.performFetch()
            }
            it("shoudl return one section") {
                expect(requestResult.count) == 1
            }
            it("Should have a fetched 1001 Task objects") {
                expect(RRC.cache.sections.first!.objects.count) == 1001
            }
        }
        describe("didInsert<T: Object>(object:indexPath:)") {
            let object = Task()
            let indexPath = NSIndexPath(forRow: 1, inSection: 2)
            beforeEach {
                RRC.didInsert(object, indexPath: indexPath)
            }
            it("Should have stored the object in the RealmResultsDelegate instance") {
                expect(RRCDelegate.object) === object
                expect(RRCDelegate.newIndexPath) === indexPath
            }
        }
        describe("didUpdate<T: Object>(object:oldIndexPath:newIndexPath:)") {
            let object = Task()
            let oldIndexPath = NSIndexPath(forRow: 4, inSection: 2)
            let newIndexPath = NSIndexPath(forRow: 1, inSection: 2)
            beforeEach {
                RRC.didUpdate(object, oldIndexPath: oldIndexPath, newIndexPath: newIndexPath)
            }
            it("Should have stored the object in the RealmResultsDelegate instance") {
                expect(RRCDelegate.object) === object
                expect(RRCDelegate.newIndexPath) === newIndexPath
                expect(RRCDelegate.oldIndexPath) === oldIndexPath
            }
        }
        describe("didDelete<T: Object>(object:indexPath:)") {
            let indexPath = NSIndexPath(forRow: 1, inSection: 2)
            beforeEach {
                RRC.didDelete(indexPath)
            }
            it("Should have stored the object in the RealmResultsDelegate instance") {
                expect(RRCDelegate.object).to(beNil())
                expect(RRCDelegate.newIndexPath) === indexPath
            }
        }
        describe("didInsertSection<T : Object>(section:index:)") {
            let section = Section<Task>(keyPath: "myKeypath", sortDescriptors: [])
            let index = 4
            beforeEach {
                RRC.didInsertSection(section, index: index)
            }
            it("Should have stored the section in the RealmResultsDelegate instance") {
                expect(RRCDelegate.section.keyPath) == section.keyPath
                expect(RRCDelegate.sectionIndex).to(equal(index))
            }
        }
        describe("didDeleteSection<T : Object>(section:index:)") {
            let section = Section<Task>(keyPath: "anotherKeypath", sortDescriptors: [])
            let index = 3
            beforeEach {
                RRC.didDeleteSection(section, index: index)
            }
            it("Should have stored the section in the RealmResultsDelegate instance") {
                expect(RRCDelegate.section.keyPath) == section.keyPath
                expect(RRCDelegate.sectionIndex).to(equal(index))
            }
        }
        
        describe("didReceiveRealmChanges(notification:)") {
            var temporaryAdded: [Task] = []
            var temporaryDeleted: [RealmChange] = []
            var temporaryUpdated: [Task] = []
            beforeEach {
                RRC = RealmResultsController<Task, Task>(forTESTRequest: request, sectionKeyPath: nil) { $0 }
                RRC.delegate = RRCDelegate
            }
            
            context("it receives an object of another model") {
                beforeEach {
                    temporaryAdded = RRC.temporaryAdded
                    temporaryUpdated = RRC.temporaryUpdated
                    temporaryDeleted = RRC.temporaryDeleted
                    let createChange = RealmChange(type: User.self, primaryKey: -111, action: .Create, mirror: User())
                    RRC.didReceiveRealmChanges(NSNotification(name: "", object: [createChange]))
                }
                it("ignores the object") {
                    expect(temporaryAdded) == RRC.temporaryAdded
                    expect(temporaryUpdated) == RRC.temporaryUpdated
                    expect(temporaryDeleted.count) == RRC.temporaryDeleted.count
                }
            }
            
            context("If the notification has the wrong format") {
                var temporaryAdded: [Task] = []
                var temporaryDeleted: [RealmChange] = []
                var temporaryUpdated: [Task] = []
                beforeEach {
                    temporaryAdded = RRC.temporaryAdded
                    temporaryUpdated = RRC.temporaryUpdated
                    temporaryDeleted = RRC.temporaryDeleted
                    RRC.didReceiveRealmChanges(NSNotification(name: "", object: nil))
                }
                it("Should have the same temporary arrays as previously") {
                    expect(temporaryAdded).to(equal(RRC.temporaryAdded))
                    expect(temporaryUpdated).to(equal(RRC.temporaryUpdated))
                    expect(temporaryDeleted.count).to(equal(RRC.temporaryDeleted.count))
                    expect(RRC.cache.sections.count).to(equal(0))
                }
            }
            context("If the notification is EMPTY") {
                let notifObject: [RealmChange] = []
                beforeEach {
                    RRC.didReceiveRealmChanges(NSNotification(name: "", object: notifObject))
                }
                it("Should not have added anything to the cache") {
                    expect(RRC.cache.sections.count).to(equal(0))
                }
            }
            
            context("If the notification has the CORRECT format") {
                var createChange: RealmChange!
                var updateChange: RealmChange!
                var deleteChange: RealmChange!
                var notifObject: [RealmChange] = []
                let task1 = Task()
                let task2 = Task()
                let task3 = Task()
                beforeEach {
                    RRC.request.realm.write {
                        task1.id = -111
                        task2.id = -222
                        task3.id = -333
                        RRC.request.realm.add(task1)
                        RRC.request.realm.add(task2)
                        RRC.request.realm.add(task3)
                    }
                    createChange = RealmChange(type: Task.self, primaryKey: -111, action: .Create, mirror: getMirror(task1))
                    updateChange = RealmChange(type: Task.self, primaryKey: -222, action: .Update, mirror: getMirror(task2))
                    deleteChange = RealmChange(type: Task.self, primaryKey: -333, action: .Delete, mirror: getMirror(task3))
                    notifObject = [createChange, updateChange, deleteChange]
                    RRC.didReceiveRealmChanges(NSNotification(name: "", object: notifObject))
                }
                afterEach {
                    RRC.request.realm.write {
                        RRC.request.realm.delete([task1, task2, task3])
                    }
                }
                it("Should have the fetched objects added on the cache") {
                    expect(RRC.cache.sections.count).to(equal(1))
                    expect(RRC.cache.sections.first!.allObjects.count).to(equal(2))
                }
            }
        }
        describe("pendingChanges()") {
            context("If there are no pending changes") {
                beforeEach {
                    RRC.temporaryAdded.removeAll()
                    RRC.temporaryAdded.removeAll()
                    RRC.temporaryAdded.removeAll()
                }
                it("Should return false") {
                    expect(RRC.pendingChanges()).to(beFalsy())
                }
            }
            context("If there are pending changes") {
                beforeEach {
                    RRC.temporaryAdded.append(Task())
                    RRC.temporaryAdded.append(Task())
                    RRC.temporaryAdded.append(Task())
                }
                it("Should return true") {
                    expect(RRC.pendingChanges()).to(beTruthy())
                }
            }

        }
        describe("finishWriteTransaction()") {
            var cacheSections: [Section<Task>]!
            context("If there are no pending changes") {
                beforeEach {
                    RRC.temporaryAdded.removeAll()
                    RRC.temporaryAdded.removeAll()
                    RRC.temporaryAdded.removeAll()
                    cacheSections = (RRC.cache?.sections)!
                }
                it("Should return false") {
                    expect(RRC.pendingChanges()).to(beFalsy())
                    expect(RRC.cache?.sections).to(equal(cacheSections))
                }
            }
        }
    }
}