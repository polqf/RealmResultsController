//
//  File.swift
//  RealmResultsController
//
//  Created by Isaac Roldan on 6/8/15.
//  Copyright © 2015 Redbooth. All rights reserved.
//

import Foundation
import Quick
import Nimble
import RealmSwift

@testable import RealmResultsController

class SectionSpec: QuickSpec {
    
    override func spec() {
        var sortDescriptors: [NSSortDescriptor]!
        var section: Section<Task>!
        var openTask: Task!
        var resolvedTask: Task!
    
        
        beforeSuite {
            sortDescriptors = [NSSortDescriptor(key: "name", ascending: false)]
            section = Section<Task>(keyPath: "keyPath", sortDescriptors: sortDescriptors)
            openTask = Task()
            openTask.id = 1500
            openTask.name = "aatest"
            openTask.resolved = false
            
            resolvedTask = Task()
            resolvedTask.id = 1501
            resolvedTask.name = "bbtest"
            resolvedTask.resolved = false
        }
        
        describe("create a Section object") {
            it("has everything you need to get started") {
                expect(section.keyPath).to(equal("keyPath"))
                expect(section.sortDescriptors).to(equal(sortDescriptors))
            }
        }
        
        describe("insertSorted") {
            
            var index: Int!
            context("when the section is empty") {
                it ("beforeAll") {
                    index = section.insertSorted(openTask)
                }
                it("a has one item") {
                    expect(section.objects.count).to(equal(1))
                }
                it("item has index 0") {
                    expect(index).to(equal(0))
                }
            }
            
            context("when the section is not empty") {
                it("beforeAll") {
                    index = section.insertSorted(resolvedTask)
                }
                it("has two items") {
                    expect(section.objects.count).to(equal(2))
                }
                it("has index 0") { // beacuse of the sortDescriptor
                    expect(index).to(equal(0))
                }
            }
        }
        
        describe("delete") {
            var originalIndex: Int!
            var index: Int!
            context("when the object exists in section") {
                beforeEach {
                    section = Section<Task>(keyPath: "keyPath", sortDescriptors: sortDescriptors)
                    section.insertSorted(resolvedTask)
                    originalIndex = section.insertSorted(openTask)
                    index = section.delete(openTask)
                }
                it("removes it from array") {
                    expect(section.objects.containsObject(openTask)).to(beFalsy())
                }
                it("returns the index of the deleted object") {
                    expect(index).to(equal(originalIndex))
                }
            }
            
            context("the object does not exists in section") {
                var anotherTask: Task!
                beforeEach {
                    section = Section<Task>(keyPath: "keyPath", sortDescriptors: sortDescriptors)
                    section.insertSorted(resolvedTask)
                    section.insertSorted(openTask)
                    anotherTask = Task()
                    index = section.delete(anotherTask)
                }
                it("returns index -1") {
                    expect(index).to(equal(-1))
                }
            }
        }
        
        describe("deleteOutdatedObject") {
            var originalIndex: Int!
            var index: Int!
            context("when the object exists in section") {
                beforeEach {
                    section = Section<Task>(keyPath: "keyPath", sortDescriptors: sortDescriptors)
                    section.insertSorted(resolvedTask)
                    originalIndex = section.insertSorted(openTask)
                    index = section.delete(openTask)
                }
                it("removes it from array") {
                    expect(section.objects.containsObject(openTask)).to(beFalsy())
                }
                it("returns the index of the deleted object") {
                    expect(index).to(equal(originalIndex))
                }
            }
            var anotherTask: Task!
            context("the object does not exists in section") {
                beforeEach {
                    section = Section<Task>(keyPath: "keyPath", sortDescriptors: sortDescriptors)
                    section.insertSorted(resolvedTask)
                    section.insertSorted(openTask)
                    anotherTask = Task()
                    index = section.delete(anotherTask)
                }
                it("returns index -1") {
                    expect(index).to(equal(-1))
                }
            }
        }
        
    }
}



class CacheDelegateMock: RealmResultsCacheDelegate {
    
    static let sharedInstance = CacheDelegateMock()
    
    var index = -1
    var oldIndexPath: NSIndexPath?
    var indexPath: NSIndexPath?
    var object: Object?
    
    func reset() {
        index = -1
        oldIndexPath = nil
        indexPath = nil
        object = nil
    }
    
    func didInsertSection<T: Object>(section: Section<T>, index: Int) {
        self.index = index
    }
    
    func didDeleteSection<T: Object>(section: Section<T>, index: Int) {
        self.index = index
    }
    
    func didInsert<T: Object>(object: T, indexPath: NSIndexPath) {
        self.object = object as Object
        self.indexPath = indexPath
    }
    func didDelete<T: Object>(object: T, indexPath: NSIndexPath) {
        self.object = object as Object
        self.indexPath = indexPath
    }
    func didUpdate<T: Object>(object: T, oldIndexPath: NSIndexPath, newIndexPath: NSIndexPath) {
        self.object = object as Object
        self.oldIndexPath = oldIndexPath
        self.indexPath = newIndexPath
    }
}



class CacheSpec: QuickSpec {
    
    override func spec() {
        
        var cache: RealmResultsCache<Task>!
        var initialObjects: [Task]!
        var request: RealmRequest<Task>!
        var realm: Realm!
        var predicate: NSPredicate!
        var sortDescriptors: [SortDescriptor]!
        var resolvedTasks: [Task]!
        var notResolvedTasks: [Task]!
        
        func initWithKeypath() {
            predicate = NSPredicate(format: "id < %d", 50)
            sortDescriptors = [SortDescriptor(property: "name", ascending: true)]
            request = RealmRequest<Task>(predicate: predicate, realm: realm, sortDescriptors: sortDescriptors, sectionKeyPath: nil)
            initialObjects = request.execute().toArray(Task.self).sort { $0.name < $1.name }
            resolvedTasks = initialObjects.filter { $0.resolved }
            notResolvedTasks = initialObjects.filter { !$0.resolved }
            cache = RealmResultsCache<Task>(objects: initialObjects, request: request)
            cache.delegate = CacheDelegateMock.sharedInstance
        }
        
        func initWithoutKeypath() {
            predicate = NSPredicate(format: "id < %d", 50)
            sortDescriptors = [SortDescriptor(property: "name", ascending: true)]
            request = RealmRequest<Task>(predicate: predicate, realm: realm, sortDescriptors: sortDescriptors, sectionKeyPath: "resolved")
            initialObjects = request.execute().toArray(Task.self)
            resolvedTasks = initialObjects.filter { $0.resolved }
            notResolvedTasks = initialObjects.filter { !$0.resolved }
            cache = RealmResultsCache<Task>(objects: initialObjects, request: request)
            cache.delegate = CacheDelegateMock.sharedInstance
        }
        
        beforeSuite {
            RealmTestHelper.loadRealm()
            realm = try! Realm()
        }
        
        describe("init") {
            context("request has no keypath") {
                beforeEach {
                    initWithKeypath()
                }
                it("inserts the received objects in one section") {
                    expect(cache.sections.count) == 1
                }
                it("section has all the objects") {
                    expect(cache.sections.first!.objects.count) == initialObjects.count
                }
            }
            
            context("request has keypath") {
                beforeEach {
                    initWithoutKeypath()
                }
                it("inserts the objects in 2 sections") {
                    expect(cache.sections.count) == 2
                }
            }
        }
        
        beforeEach {
            CacheDelegateMock.sharedInstance.reset()
        }
        
        describe("insert") {
            context("with section keypath") {
                var newTask: Task!
                var cacheIndexPath: NSIndexPath!
                var memoryIndex: Int!
                var object: Object!
                var resolvedTasksCopy: [Task]!

                it("beforeAll") {
                    //create and insert new item in cache
                    newTask = Task()
                    newTask.id = -1
                    newTask.name = "ccbbaa"
                    newTask.resolved = true
                    cache.insert([newTask])
                    
                    //replicate the behaviour (adding + sorting) in a copy array
                    resolvedTasksCopy = resolvedTasks
                    resolvedTasksCopy.append(newTask)
                    resolvedTasksCopy.sortInPlace {$0.name < $1.name}
                    memoryIndex = resolvedTasksCopy.indexOf(newTask)!
                    
                    //Get the values from the delegate
                    cacheIndexPath = CacheDelegateMock.sharedInstance.indexPath
                    object = CacheDelegateMock.sharedInstance.object
                }
                it("indexPath is not nil") {
                    expect(cacheIndexPath).toNot(beNil())
                }
                it("indexpath.row is ordered") {
                    expect(cacheIndexPath.row) == memoryIndex
                }
                it("the received object is the same than inserted") {
                    expect(object) === newTask
                }
                it("section is resolved one") {
                    let section = cache.sections[cacheIndexPath.section]
                    expect(section.keyPath) == "Optional(1)" //like this because its an optional boolean transformed to string
                }
                it("remove from cache") {
                    cache.delete([newTask])
                }
            }
            
            context("without section keypath") {
                
            }
        }
        
        describe("delete") {
            context("with section keypath") {
                
            }
            
            context("without section keypath") {
                
            }
        }
        
        describe("update") {
            context("with section keypath") {
                
            }
            
            context("without section keypath") {
                
            }
        }
    }
}

