//
//  RealmResultsControllerTests.swift
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

class RealmResultsDelegate: RealmResultsControllerDelegate {
    static let sharedInstance = RealmResultsDelegate()
    var oldIndexPath: NSIndexPath?
    var newIndexPath: NSIndexPath?
    var sectionIndex: Int = 0
    var changeType: RealmResultsChangeType = .Move
    var object: Task?
    var section: RealmSection<Task>!
    
    func willChangeResults(controller: AnyObject) {}
    
    func didChangeObject<U>(controller: AnyObject, object: U, oldIndexPath: NSIndexPath, newIndexPath: NSIndexPath, changeType: RealmResultsChangeType) {
        self.object = object as? Task
        self.oldIndexPath = oldIndexPath
        self.newIndexPath = newIndexPath
        self.changeType = changeType
    }
    
    func didChangeSection<U>(controller: AnyObject, section: RealmSection<U>, index: Int, changeType: RealmResultsChangeType) {
        self.section = section as? RealmSection<Task>
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
            request = RealmRequest<Task>(predicate: predicate, realm: realm, sortDescriptors: [SortDescriptor(property: "id")])
            RRC = try! RealmResultsController<Task, Task>(forTESTRequest: request, sectionKeyPath: nil) { $0 }
            RRC.delegate = RRCDelegate
        }

        afterSuite {
            RRC.delegate = nil
            RRC = nil
        }
        
        describe("sections") {
            beforeEach {
                RRC.performFetch()
            }
            it("has created 1 section") {
                expect(RRC.sections.count) == 1
            }
        }
        
        describe("init(request:sectionKeyPath:mapper:)") {
            var createdRRC: RealmResultsController<Task, Task>!
            
            beforeEach {
                createdRRC = try! RealmResultsController<Task, Task>(request: request, sectionKeyPath: nil, mapper: {$0}, filter: nil)
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
            
            it("try to execute a block in main thread from a background queue synced") {
                let queue = dispatch_queue_create("lock", DISPATCH_QUEUE_SERIAL)
                dispatch_async(queue) {
                    RRC.executeOnMainThread(true) { }
                }
            }
            
            context("using valid mapper") {
                var createdRRC: RealmResultsController<Task, TaskModel>!
                var sameType: Bool = false
                beforeEach {
                    let request = RealmRequest<Task>(predicate: NSPredicate(value: true), realm: realm, sortDescriptors: [SortDescriptor(property: "id")])
                    createdRRC = try! RealmResultsController<Task, TaskModel>(request: request, sectionKeyPath: nil, mapper: Task.mapTask)
                    createdRRC.performFetch()
                    let object = createdRRC.objectAt(NSIndexPath(forRow: 0, inSection: 0))
                    sameType = object.isKindOfClass(TaskModel)
                }
                it("returns mapped object") {
                    expect(sameType).to(beTruthy())
                }
            }
            
            context("KeyPath Is not the same as the first sortDescriptor") {
                var exceptionDetected: Bool = false
                
                beforeEach {
                    do  {
                        let request = RealmRequest<Task>(predicate: NSPredicate(value: true), realm: realm, sortDescriptors: [SortDescriptor(property: "name")])
                        let _ = try RealmResultsController<Task, TaskModel>(request: request, sectionKeyPath: "something", mapper: Task.mapTask)
                    } catch {
                        exceptionDetected = true
                    }
                }
                it("it launches an exception") {
                    expect(exceptionDetected).to(beTruthy())
                }
            }
            
            context("RRC doesn't have any Sorts") {
                var exceptionDetected: Bool = false
                beforeEach {
                    do  {
                        let request = RealmRequest<Task>(predicate: NSPredicate(value: true), realm: realm, sortDescriptors: [])
                        let _ = try RealmResultsController<Task, TaskModel>(request: request, sectionKeyPath: "something", mapper: Task.mapTask)
                    } catch {
                        exceptionDetected = true
                    }
                }
                it("it launches an exception") {
                    expect(exceptionDetected).to(beTruthy())
                }
            }
            
            context("If the request sorts are empty") {
                var exceptionDetected: Bool = false
                beforeEach {
                    do  {
                        let request = RealmRequest<Task>(predicate: NSPredicate(value: true), realm: realm, sortDescriptors: [])
                        let _ = try RealmResultsController<Task, TaskModel>(request: request, sectionKeyPath: "something", mapper: Task.mapTask)
                    } catch {
                        exceptionDetected = true
                    }
                }
                it("it launches an exception") {
                    expect(exceptionDetected).to(beTruthy())
                }
            }
        }
        
        //Without Mapper
        describe("init(request:sectionKeyPath)") {
            var createdRRC: RealmResultsController<Task, Task>!
            
            beforeEach {
                createdRRC = try! RealmResultsController<Task, Task>(request: request, sectionKeyPath: nil)
            }
            it("Should have initialized a RRC") {
                expect(createdRRC).toNot(beNil())
                expect(createdRRC.request).toNot(beNil())
                expect(createdRRC.mapper).toNot(beNil())
                expect(createdRRC.cache.delegate).toNot(beNil())
                expect(createdRRC.cache.defaultKeyPathValue).to(equal("default"))
            }
            
            context("the mapper returns an object of the same type") {
                var sameType: Bool = false
                beforeEach {
                    createdRRC.performFetch()
                    let object = createdRRC.objectAt(NSIndexPath(forRow: 0, inSection: 0))
                    sameType = object.isKindOfClass(Task)
                }
                it("returns mapped object") {
                    expect(sameType).to(beTruthy())
                }
            }
        }
        
        //With filter
        describe("init(request:sectionKeyPath:mapper:filter:)") {
            var createdRRC: RealmResultsController<Task, Task>!
            
            beforeEach {
                createdRRC = try! RealmResultsController<Task, Task>(request: request, sectionKeyPath: nil, mapper: {$0}, filter: { (task: Task) in task.resolved})
            }
            it("Should have initialized a RRC") {
                expect(createdRRC).toNot(beNil())
                expect(createdRRC.request).toNot(beNil())
                expect(createdRRC.mapper).toNot(beNil())
                expect(createdRRC.filter).toNot(beNil())
                expect(createdRRC.cache.delegate).toNot(beNil())
                expect(createdRRC.cache.defaultKeyPathValue).to(equal("default"))
            }
            
            context("the mapper returns an object of the same type") {
                var sameType: Bool = false
                beforeEach {
                    createdRRC.performFetch()
                    let object = createdRRC.objectAt(NSIndexPath(forRow: 0, inSection: 0))
                    sameType = object.isKindOfClass(Task)
                }
                it("returns mapped object") {
                    expect(sameType).to(beTruthy())
                }
                it("all tasks are resolved") {
                    let allObjects: [Task] = createdRRC.cache.sections[0].allObjects
                    let resolved = allObjects.filter({$0.resolved})
                    expect(allObjects.count) == resolved.count
                }
                
                context("new filter") {
                    beforeEach {
                        createdRRC.updateFilter({ (task: Task) in !task.resolved})
                    }
    
                    it("all tasks are not resolved") {
                        let allObjects: [Task] = createdRRC.cache.sections[0].allObjects
                        let notResolved = allObjects.filter({!$0.resolved})
                        expect(allObjects.count) == notResolved.count
                    }
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
        
        describe("performFetch()") {
            var requestResult: [Section<Task>]!
            
            beforeEach {
                RRC.performFetch()
                requestResult = RRC.cache.sections
            }
            it("shoudl return one section") {
                expect(requestResult.count) == 1
            }
            it("Should have a fetched 1001 Task objects") {
                expect(RRC.cache.sections.first!.objects.count) == 1001
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
                fetchedObject = RRC.cache.sections[0].objects[5] as? Task
                object = RRC.objectAt(NSIndexPath(forRow: 5, inSection: 0))
            }
            it("returns the correct object") {
                expect(object) == fetchedObject
            }
        }
        describe("didInsert<T: Object>(object:indexPath:)") {
            var object: Task!
            let indexPath = NSIndexPath(forRow: 1, inSection: 2)
            beforeEach {
                object = Task()
                RRC.didInsert(object, indexPath: indexPath)
            }
            it("Should have stored the object in the RealmResultsDelegate instance") {
                expect(RRCDelegate.object) === object
                expect(RRCDelegate.newIndexPath) === indexPath
            }
        }
        
        describe("didUpdate<T: Object>(object:oldIndexPath:newIndexPath:)") {
            var object: Task!
            let oldIndexPath = NSIndexPath(forRow: 4, inSection: 2)
            let newIndexPath = NSIndexPath(forRow: 1, inSection: 2)
            beforeEach {
                object = Task()
                RRC.didUpdate(object, oldIndexPath: oldIndexPath, newIndexPath: newIndexPath, changeType: .Move)
            }
            it("Should have stored the object in the RealmResultsDelegate instance") {
                expect(RRCDelegate.object) === object
                expect(RRCDelegate.newIndexPath) === newIndexPath
                expect(RRCDelegate.oldIndexPath) === oldIndexPath
            }
        }
        describe("didDelete<T: Object>(object:indexPath:)") {
            let indexPath = NSIndexPath(forRow: 1, inSection: 2)
            var task: Task!
            beforeEach {
                task = Task()
                RRC.didDelete(task, indexPath: indexPath)
            }
            it("Should have stored the object in the RealmResultsDelegate instance") {
                expect(RRCDelegate.object) == task
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
            var temporaryDeleted: [Task] = []
            var temporaryUpdated: [Task] = []
            beforeEach {
                RRC = try! RealmResultsController<Task, Task>(forTESTRequest: request, sectionKeyPath: nil) { $0 }
                RRC.delegate = RRCDelegate
            }
            
            context("it receives an object of another model") {
                beforeEach {
                    temporaryAdded = RRC.temporaryAdded
                    temporaryUpdated = RRC.temporaryUpdated
                    temporaryDeleted = RRC.temporaryDeleted
                    let createChange = RealmChange(type: User.self, action: .Create, mirror: User())
                    RRC.didReceiveRealmChanges(NSNotification(name: "", object: [realm.path : [createChange]]))
                }
                it("ignores the object") {
                    expect(temporaryAdded) == RRC.temporaryAdded
                    expect(temporaryUpdated) == RRC.temporaryUpdated
                    expect(temporaryDeleted.count) == RRC.temporaryDeleted.count
                }
            }
            
            context("If the notification has the wrong format") {
                var temporaryAdded: [Task] = []
                var temporaryDeleted: [Task] = []
                var temporaryUpdated: [Task] = []
                beforeEach {
                    temporaryAdded = RRC.temporaryAdded
                    temporaryUpdated = RRC.temporaryUpdated
                    temporaryDeleted = RRC.temporaryDeleted
                    RRC.didReceiveRealmChanges(NSNotification(name: "", object: ["wrongRealm" : [RealmChange]()]))
                }
                it("Should have the same temporary arrays as previously") {
                    expect(temporaryAdded).to(equal(RRC.temporaryAdded))
                    expect(temporaryUpdated).to(equal(RRC.temporaryUpdated))
                    expect(temporaryDeleted.count).to(equal(RRC.temporaryDeleted.count))
                    expect(RRC.cache.sections.count).to(equal(0))
                }
            }
            context("If the notification comes from a different Realm") {
                var temporaryAdded: [Task] = []
                var temporaryDeleted: [Task] = []
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
                var notifObject: [String :[RealmChange]] = [:]
                beforeEach {
                    notifObject = [realm.path : [RealmChange]()]
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
                var notifObject: [String : [RealmChange]] = [:]
                var task1: Task!
                var task2: Task!
                var task3: Task!
                beforeEach {
                    task1 = Task()
                    task2 = Task()
                    task3 = Task()
                    try! RRC.request.realm.write {
                        task1.id = -111
                        task2.id = -222
                        task3.id = -333
                        RRC.request.realm.add(task1)
                        RRC.request.realm.add(task2)
                        RRC.request.realm.add(task3)
                    }
                    RRC.updateFilter({T in true})
                    RRC.performFetch()
                    RRC.cache.sections.first?.objects.removeAllObjects()
                    RRC.cache.sections.first?.objects.addObject(task2)
                    RRC.cache.sections.first?.objects.addObject(task3)
                    createChange = RealmChange(type: Task.self, action: .Create, mirror: getMirror(task1))
                    updateChange = RealmChange(type: Task.self, action: .Update, mirror: getMirror(task2))
                    deleteChange = RealmChange(type: Task.self, action: .Delete, mirror: getMirror(task3))
                    notifObject = [realm.path : [createChange, updateChange, deleteChange]]
                    RRC.didReceiveRealmChanges(NSNotification(name: "", object: notifObject))
                }
                afterEach {
                    try! RRC.request.realm.write {
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
                    RRC.temporaryUpdated.removeAll()
                    RRC.temporaryDeleted.removeAll()
                }
                it("Should return false") {
                    expect(RRC.pendingChanges()).to(beFalsy())
                }
            }
            context("If there are pending changes") {
                beforeEach {
                    RRC.temporaryAdded.append(Task())
                    RRC.temporaryDeleted.append(Task())
                    RRC.temporaryUpdated.append(Task())
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
                    RRC.temporaryUpdated.removeAll()
                    RRC.temporaryDeleted.removeAll()
                    cacheSections = (RRC.cache?.sections)!
                }
                it("Should return false") {
                    expect(RRC.pendingChanges()).to(beFalsy())
                    expect(RRC.cache?.sections).to(equal(cacheSections))
                }
            }
            context("If the temporaryUpdated contains a MOVE") {
                beforeEach {
                    let sorts = [SortDescriptor(property: "name", ascending: true)]
                    let request = RealmRequest<Task>(predicate: NSPredicate(value: true), realm: realm, sortDescriptors: sorts)
                    RRC = try! RealmResultsController<Task, Task>(forTESTRequest: request, sectionKeyPath: nil) { $0 }
                    RRC.delegate = RRCDelegate
                    let task = Task()
                    task.id = 12
                    task.name = "bbb"
                    let task2 = Task()
                    task2.id = 13
                    task2.name = "ccc"
                    
                    RRC.cache.reset([task, task2])
                    task2.name = "aaa"
                    RRC.temporaryUpdated.append(task2)
                    let notif = NSNotification(name: "", object: [realm.path : [RealmChange]()])
                    RRC.didReceiveRealmChanges(notif)
                }
                it("Should return false") {
                    expect(RRC.pendingChanges()).to(beFalsy())
                }
            }
        }
    }
}