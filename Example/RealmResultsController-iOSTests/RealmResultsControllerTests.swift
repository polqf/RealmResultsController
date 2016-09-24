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
    var oldIndexPath: IndexPath?
    var newIndexPath: IndexPath?
    var sectionIndex: Int = 0
    var changeType: RealmResultsChangeType = .Move
    var object: Task?
    var section: RealmSection<Task>!
    
    func willChangeResults(_ controller: AnyObject) {}
    
    func didChangeObject<U>(_ controller: AnyObject, object: U, oldIndexPath: IndexPath, newIndexPath: IndexPath, changeType: RealmResultsChangeType) {
        self.object = object as? Task
        self.oldIndexPath = oldIndexPath
        self.newIndexPath = newIndexPath
        self.changeType = changeType
    }
    
    func didChangeSection<U>(_ controller: AnyObject, section: RealmSection<U>, index: Int, changeType: RealmResultsChangeType) {
        self.section = section as? RealmSection<Task>
        self.sectionIndex = index
        self.changeType = changeType
    }

    
    func didChangeResults(_ controller: AnyObject) {}
}

class RealmResultsControllerSpec: QuickSpec {

    override func spec() {
        var realm: Realm!
        var request: RealmRequest<Task>!
        var RRC: RealmResultsController<Task, Task>!
        let RRCDelegate = RealmResultsDelegate()
        
        beforeSuite {
            RealmTestHelper.loadRealm()
            realm = try! Realm()
            let predicate = NSPredicate(value: true)
            request = RealmRequest<Task>(predicate: predicate, realm: realm, sortDescriptors: [RealmSwift.SortDescriptor(property: "id")])
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
                let queue = DispatchQueue(label: "lock")
                queue.async {
                    Threading.executeOnMainThread { }
                }
            }
            
            it("try to execute a block in main thread from a background queue synced") {
                let queue = DispatchQueue(label: "lock")
                queue.async {
                    Threading.executeOnMainThread(true) { }
                }
            }
            
            context("using valid mapper") {
                var createdRRC: RealmResultsController<Task, TaskModel>!
                var sameType: Bool = false
                beforeEach {
                    let request = RealmRequest<Task>(predicate: NSPredicate(value: true), realm: realm, sortDescriptors: [RealmSwift.SortDescriptor(property: "id")])
                    createdRRC = try! RealmResultsController<Task, TaskModel>(request: request, sectionKeyPath: nil, mapper: Task.mapTask)
                    createdRRC.performFetch()
                    let object = createdRRC.object(at: IndexPath(row: 0, section: 0))
                    sameType = object.isKind(of: TaskModel.self)
                }
                it("returns mapped object") {
                    expect(sameType).to(beTruthy())
                }
            }
            
            context("KeyPath Is not the same as the first sortDescriptor") {
                var exceptionDetected: Bool = false
                
                beforeEach {
                    do  {
                        let request = RealmRequest<Task>(predicate: NSPredicate(value: true), realm: realm, sortDescriptors: [RealmSwift.SortDescriptor(property: "name")])
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
                    let object = createdRRC.object(at: IndexPath(row: 0, section: 0))
                    sameType = object.isKind(of: Task.self)
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
                    let object = createdRRC.object(at: IndexPath(row: 0, section: 0))
                    sameType = object.isKind(of: Task.self)
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
                total = RRC.numberOfObjects(at: 0)
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
                object = RRC.object(at: IndexPath(row: 5, section: 0))
            }
            it("returns the correct object") {
                expect(object) == fetchedObject
            }
        }
        describe("didInsert<T: Object>(object:indexPath:)") {
            var object: Task!
            let indexPath = IndexPath(row: 1, section: 2)
            beforeEach {
                object = Task()
                RRC.didInsert(object, indexPath: indexPath)
            }
            it("Should have stored the object in the RealmResultsDelegate instance") {
                expect(RRCDelegate.object) === object
                expect(RRCDelegate.newIndexPath) == indexPath
            }
        }
        
        describe("didUpdate<T: Object>(object:oldIndexPath:newIndexPath:)") {
            var object: Task!
            let oldIndexPath = IndexPath(row: 4, section: 2)
            let newIndexPath = IndexPath(row: 1, section: 2)
            beforeEach {
                object = Task()
                RRC.didUpdate(object, oldIndexPath: oldIndexPath, newIndexPath: newIndexPath, changeType: .Move)
            }
            it("Should have stored the object in the RealmResultsDelegate instance") {
                expect(RRCDelegate.object) === object
                expect(RRCDelegate.newIndexPath) == newIndexPath
                expect(RRCDelegate.oldIndexPath) == oldIndexPath
            }
        }
        describe("didDelete<T: Object>(object:indexPath:)") {
            let indexPath = IndexPath(row: 1, section: 2)
            var task: Task!
            beforeEach {
                task = Task()
                RRC.didDelete(task, indexPath: indexPath)
            }
            it("Should have stored the object in the RealmResultsDelegate instance") {
                expect(RRCDelegate.object) == task
                expect(RRCDelegate.newIndexPath) == indexPath
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
                RRC.queueManager = RealmQueueManager(sync: true)
            }
            
            context("it receives an object of another model") {
                beforeEach {
                    temporaryAdded = RRC.temporaryAdded
                    temporaryUpdated = RRC.temporaryUpdated
                    temporaryDeleted = RRC.temporaryDeleted
                    let createChange = RealmChange(type: User.self, action: .add, mirror: User())
                    RRC.didReceiveRealmChanges(NSNotification(name: NSNotification.Name(rawValue: ""), object: [realm.realmIdentifier : [createChange]]))
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
                    RRC.didReceiveRealmChanges(NSNotification(name: NSNotification.Name(rawValue: ""), object: ["wrongRealm" : [RealmChange]()]))
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
                    RRC.didReceiveRealmChanges(NSNotification(name: NSNotification.Name(rawValue: ""), object: nil))
                }
                it("Should have the same temporary arrays as previously") {
                    expect(temporaryAdded).to(equal(RRC.temporaryAdded))
                    expect(temporaryUpdated).to(equal(RRC.temporaryUpdated))
                    expect(temporaryDeleted.count).to(equal(RRC.temporaryDeleted.count))
                    expect(RRC.cache.sections.count).to(equal(0))
                }
            }
            context("If the notification is EMPTY") {
                var notifObject: [String : [RealmChange]] = [:]
                beforeEach {
                    notifObject = [realm.realmIdentifier : [RealmChange]()]
                    RRC.didReceiveRealmChanges(NSNotification(name: NSNotification.Name(rawValue: ""), object: notifObject))
                }
                it("Should not have added anything to the cache") {
                    expect(RRC.cache.sections.count).to(equal(0))
                }
            }
            
            context("if the notification has the CORRECT format") {
                context("we receive an update and a deletion") {
                    var updateChange: RealmChange!
                    var deleteChange: RealmChange!
                    var notifObject: [String : [RealmChange]] = [:]
                    var task2: Task!
                    var task3: Task!
                    beforeEach {
                        task2 = Task()
                        task2.id = -222
                        task3 = Task()
                        task3.id = -333
                        try! RRC.request.realm.write {
                            RRC.request.realm.add(task2)
                            RRC.request.realm.add(task3)
                        }
                        RRC.updateFilter({T in true})
                        RRC.performFetch()
                        RRC.cache.sections.first?.objects.removeAllObjects()
                        RRC.cache.sections.first?.objects.add(task2)
                        RRC.cache.sections.first?.objects.add(task3)
                        updateChange = RealmChange(type: Task.self, action: .update, mirror: task2.getMirror())
                        deleteChange = RealmChange(type: Task.self, action: .delete, mirror: task3.getMirror())
                        notifObject = [realm.realmIdentifier : [updateChange, deleteChange]]
                        RRC.didReceiveRealmChanges(NSNotification(name: NSNotification.Name(rawValue: ""), object: notifObject))
                    }
                    afterEach {
                        try! RRC.request.realm.write {
                            RRC.request.realm.delete([task2, task3])
                        }
                    }
                    it("Should have the fetched objects added on the cache") {
                        expect(RRC.cache.sections.count).to(equal(1))
                        expect(RRC.cache.sections.first!.allObjects.count).to(equal(1))
                    }
                }
                context("we receive an update and a creation") {
                    var createChange: RealmChange!
                    var updateChange: RealmChange!
                    var notifObject: [String : [RealmChange]] = [:]
                    var task1: Task!
                    var task2: Task!
                    beforeEach {
                        task1 = Task()
                        task1.id = -111
                        task2 = Task()
                        task2.id = -222
                        try! RRC.request.realm.write {
                            RRC.request.realm.add(task1)
                            RRC.request.realm.add(task2)
                        }
                        RRC.updateFilter({T in true})
                        RRC.performFetch()
                        RRC.cache.sections.first?.objects.removeAllObjects()
                        RRC.cache.sections.first?.objects.add(task2)
                        createChange = RealmChange(type: Task.self, action: .add, mirror: task1.getMirror())
                        updateChange = RealmChange(type: Task.self, action: .update, mirror: task2.getMirror())
                        notifObject = [realm.realmIdentifier : [createChange, updateChange]]
                        RRC.didReceiveRealmChanges(NSNotification(name: NSNotification.Name(rawValue: ""), object: notifObject))
                    }
                    afterEach {
                        try! RRC.request.realm.write {
                            RRC.request.realm.delete([task1, task2])
                        }
                    }
                    it("Should have the fetched objects added on the cache") {
                        expect(RRC.cache.sections.count).to(equal(1))
                        expect(RRC.cache.sections.first!.allObjects.count).to(equal(2))
                    }
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
            context("If there are no pending changes") {
                var cacheSections: [Section<Task>]!
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
        }
        describe("removeDuplicates") {
            beforeEach {
                RRC.temporaryAdded.removeAll()
                RRC.temporaryUpdated.removeAll()
                RRC.temporaryDeleted.removeAll()
            }
            context("Adding object and removing it in the same transaction") {
                let id = 5
                beforeEach {
                    RRC.temporaryAdded = [NewTask(id)]
                    RRC.temporaryDeleted = [NewTask(id)]
                    RRC.removeDuplicates()
                }
                it("should only contain the task as deletion") {
                    expect(RRC.temporaryAdded.count) == 0
                    expect(RRC.temporaryUpdated.count) == 0
                    expect(RRC.temporaryDeleted.count) == 1
                }
                it("should contain the task with id = 5") {
                    expect(RRC.temporaryDeleted.first!.id) == id
                }
            }
            context("Adding object and updating it in the same transaction") {
                let id = 5
                beforeEach {
                    RRC.temporaryAdded = [NewTask(id)]
                    RRC.temporaryUpdated = [NewTask(id)]
                    RRC.removeDuplicates()
                }
                it("should only contain the task as update") {
                    expect(RRC.temporaryAdded.count) == 0
                    expect(RRC.temporaryUpdated.count) == 1
                    expect(RRC.temporaryDeleted.count) == 0
                }
                it("should contain the task with id = 5") {
                    expect(RRC.temporaryUpdated.first!.id) == id
                }
            }
            context("Deleting object and updating it in the same transaction") {
                let id = 5
                beforeEach {
                    RRC.temporaryUpdated = [NewTask(id)]
                    RRC.temporaryDeleted = [NewTask(id)]
                    RRC.removeDuplicates()
                }
                it("should only contain the task as deletion") {
                    expect(RRC.temporaryAdded.count) == 0
                    expect(RRC.temporaryUpdated.count) == 0
                    expect(RRC.temporaryDeleted.count) == 1
                }
                it("should contain the task with id = 5") {
                    expect(RRC.temporaryDeleted.first!.id) == id
                }
            }
        }
    }
}
