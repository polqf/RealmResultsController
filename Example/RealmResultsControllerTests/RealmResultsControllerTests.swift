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
    var object: Task!
    var section: RealmSection<Task>!
    
    func willChangeResults(controller: AnyObject) {}
    
    func didChangeObject<U>(object: U, controller: AnyObject, atIndexPath: NSIndexPath, newIndexPath: NSIndexPath, changeType: RealmResultsChangeType) {
        self.object = object as! Task
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
            RRC = RealmResultsController<Task, Task>(request: request, sectionKeyPath: nil) { $0 }
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
        }
        
        describe("allObjects") {
            var results: [Task]!
            beforeEach {
                RRC.performFetch()
                results = RRC.allObjects
            }
            it("returns 1001 objects") {
                expect(results.count) == 1001
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
                expect(requestResult.first!.objects.count).to(equal(1001))
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
            let object = Task()
            let indexPath = NSIndexPath(forRow: 1, inSection: 2)
            beforeEach {
                RRC.didDelete(indexPath)
            }
            it("Should have stored the object in the RealmResultsDelegate instance") {
                expect(RRCDelegate.object) === object
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
            context("If the notification has the wrong format") {
                var temporaryAdded: [Task] = []
                var temporaryDeleted: [RealmChange] = []
                var temporaryUpdated: [Task] = []
                beforeEach {
                    RRC.didReceiveRealmChanges(NSNotification(name: "", object: nil))
                    temporaryAdded = RRC.temporaryAdded
                    temporaryUpdated = RRC.temporaryUpdated
                    temporaryDeleted = RRC.temporaryDeleted
                }
                it("Should have the same temporary arrays as previously") {
                    expect(temporaryAdded).to(equal(RRC.temporaryAdded))
                    expect(temporaryUpdated).to(equal(RRC.temporaryUpdated))
                    expect(temporaryDeleted).to(equal(RRC.temporaryDeleted))
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