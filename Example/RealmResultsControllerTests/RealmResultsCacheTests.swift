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





class CacheSpec: QuickSpec {
    
    override func spec() {
        
        var cache: RealmResultsCache<Task>!
        
        beforeSuite {
//            cache = RealmResultsCache<Task>()
        }

        
        describe("init") {
            
        }
    }
}

