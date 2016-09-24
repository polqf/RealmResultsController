//
//  RealmSectionSpec.swift
//  RealmResultsController
//
//  Created by Isaac Roldan on 7/8/15.
//  Copyright © 2015 Redbooth.
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
        
        describe("insertSorted(object:)") {
            
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
        
        describe("delete(object:)") {
            var originalIndex: Int!
            var index: Int!
            context("when the object exists in section") {
                beforeEach {
                    section = Section<Task>(keyPath: "keyPath", sortDescriptors: sortDescriptors)
                    _ = section.insertSorted(resolvedTask)
                    originalIndex = section.insertSorted(openTask)
                    index = section.delete(openTask)
                }
                it("removes it from array") {
                    expect(section.objects.contains(openTask)).to(beFalsy())
                }
                it("returns the index of the deleted object") {
                    expect(index).to(equal(originalIndex))
                }
            }
            
            context("the object does not exists in section") {
                var anotherTask: Task!
                beforeEach {
                    section = Section<Task>(keyPath: "keyPath", sortDescriptors: sortDescriptors)
                    _ = section.insertSorted(resolvedTask)
                    _ = section.insertSorted(openTask)
                    anotherTask = Task()
                    index = section.delete(anotherTask)
                }
                it("returns index nil") {
                    expect(index).to(beNil())
                }
            }
        }
        
        describe("deleteOutdatedObject(object:)") {
            var originalIndex: Int!
            var index: Int!
            context("when the object exists in section") {
                beforeEach {
                    section = Section<Task>(keyPath: "keyPath", sortDescriptors: sortDescriptors)
                    _ = section.insertSorted(resolvedTask)
                    originalIndex = section.insertSorted(openTask)
                    index = section.deleteOutdatedObject(openTask)
                }
                it("removes it from array") {
                    expect(section.objects.contains(openTask)).to(beFalsy())
                }
                it("returns the index of the deleted object") {
                    expect(index).to(equal(originalIndex))
                }
            }
            var anotherTask: Task!
            context("the object does not exists in section") {
                beforeEach {
                    section = Section<Task>(keyPath: "keyPath", sortDescriptors: sortDescriptors)
                    _ = section.insertSorted(resolvedTask)
                    _ = section.insertSorted(openTask)
                    anotherTask = Task()
                    index = section.deleteOutdatedObject(anotherTask)
                }
                it("returns index nil") {
                    expect(index).to(beNil())
                }
            }
        }
        
        describe("insert(object:)") {
            afterEach {
                section.objects.removeAllObjects()
            }
            
            context("when the section is empty") {
                beforeEach {
                    section = Section<Task>(keyPath: "keyPath", sortDescriptors: sortDescriptors)
                    section.insert(openTask)
                }
                it("has one item") {
                    expect(section.objects.count).to(equal(1))
                }
                it("item is latest") {
                    expect((section.objects.lastObject as! Task) === openTask!).to(beTrue())
                }
            }
            
            context("when the section is not empty") {
                beforeEach {
                    section.objects = [openTask]
                    section.insert(resolvedTask)
                }
                it("has two items") {
                    expect(section.objects.count).to(equal(2))
                }
                it("lastObject is resolvedTask") {
                    expect((section.objects.lastObject as! Task) === resolvedTask!).to(beTrue())
                }
            }
        }
        
        describe("sort()") {
            afterEach {
                section.objects.removeAllObjects()
            }
            
            context("when the section is not empty and we add items unsorted") {
                let aTask = Task()
                aTask.id = 1502
                aTask.name = "aaaaa"
                
                let bTask = Task()
                bTask.id = 1503
                bTask.name = "bbbbb"
                
                var aTaskIndex: Int!
                var bTaskIndex: Int!
                beforeEach {
                    let ascendingSortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
                    section = Section<Task>(keyPath: "keyPath", sortDescriptors: ascendingSortDescriptors)
                    //ADDING Tasks unsorted
                    section.insert(bTask)
                    section.insert(aTask)
                    aTaskIndex = section.objects.index(of: aTask)
                    bTaskIndex = section.objects.index(of: bTask)
                    section.sort()
                }
                
                it("the aTask should not be in the same index as before") {
                    expect(section.objects.index(of: aTask)) != aTaskIndex
                }
                it("the aTask index should be 0") {
                    expect(section.objects.index(of: aTask)) == 0
                }
                it("the bTask should not be in the same index as before") {
                    expect(section.objects.index(of: bTask)) != bTaskIndex
                }
                it("the bTask index should be 1") {
                    expect(section.objects.index(of: bTask)) == 1
                }
            }
        }
    }
}


