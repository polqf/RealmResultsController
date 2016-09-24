//
//  RealmExtensionSpec.swift
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

class RealmExtensionSpec: QuickSpec {
    
    func cleanLoggers() {
        RealmNotification.sharedInstance.loggers = []
    }
    
    override func spec() {
        
        var realm: Realm!
        var taskToTest: Task?

        beforeSuite {
            let configuration = Realm.Configuration(inMemoryIdentifier: "testingRealm")
            realm = try! Realm(configuration: configuration)
            taskToTest = Task()
            taskToTest!.id = 1500
            taskToTest!.name = "testingName1"
            self.cleanLoggers()
            try! realm.write {
                realm.addNotified([taskToTest!])
            }
        }
    
        describe("addNotified (array)") {
            it("task is inserted") {
                expect(taskToTest!.realm).toNot(beNil())
            }
            it("crates a logger for this realm") {
                expect(RealmNotification.sharedInstance.loggers.count) == 1
            }
            it("clean") {
                self.cleanLoggers()
            }
            
            
            context("the object already exists on DB") {
                var myTask: Task?
                var fetchedTask: Task!
                beforeEach {
                    self.cleanLoggers()
                    
                    fetchedTask = realm.object(ofType: Task.self, forPrimaryKey: 1)
                    
                    myTask = Task()
                    myTask!.id = 1
                    myTask!.name = "test"
                    try! realm.write {
                        realm.addNotified(myTask!, update: true)
                    }
                }
                it("trying to add the same object again, will update it") {
                    expect(myTask!.realm).toNot(beNil())
                }
                it("fetched tasks and updated one are the same") {
                    expect(fetchedTask) == myTask
                }
                it("clean") {
                    self.cleanLoggers()
                }
            }
            
            context("the Model does not have primaryKey") {
                var object: Dummy!
                beforeEach {
                    self.cleanLoggers()
                    object = Dummy()
                    object.id = 1
                    try! realm.write {
                        realm.addNotified(object)
                    }
                }
                it("will add it to the realm") {
                    expect(object.realm).toNot(beNil())
                }
                it("won't use a logger") {
                    expect(RealmNotification.sharedInstance.loggers.count) == 0
                }
                it("clean") {
                    self.cleanLoggers()
                }
            }
        }
        
        describe("createNotified") {
            var refetchedTask: Task!
            it("beforeAll") {
                try! realm.write {
                    realm.createNotified(Task.self, value: ["id":1501, "name": "testingName2"], update: true)
                }
                refetchedTask = realm.object(ofType: Task.self, forPrimaryKey: 1501)
            }
            it("task is updated") {
                expect(refetchedTask.name) == "testingName2"
            }
            it("still one logger") {
                expect(RealmNotification.sharedInstance.loggers.count) == 1
            }
            it("clean") {
                self.cleanLoggers()
            }
            
            context("the object already exists on DB") {
                var myTask: [String : Any]!
                var fetchedTask: Task!
                beforeEach {
                    self.cleanLoggers()
                    myTask = ["name" : "hola", "id" : 1501, "resolved" : 1]
                    try! realm.write {
                        realm.createNotified(Task.self, value: myTask, update: true)
                    }
                    fetchedTask = realm.object(ofType: Task.self, forPrimaryKey: 1501)

                }
                it("trying to add the same object again, will update it") {
                    expect(fetchedTask.name) == "hola"
                }
                it("clean") {
                    self.cleanLoggers()
                }
            }

            
            context("the Model does not have primaryKey") {
                var object: [String : Any]!
                var totalObjectsBefore: Int!
                var totalObjectsAfter: Int!
                beforeEach {
                    self.cleanLoggers()
                    totalObjectsBefore = realm.objects(Task.self).count
                    object = ["name" : "hola"]
                    try! realm.write {
                        realm.createNotified(Dummy.self, value: object, update: true)
                    }
                    totalObjectsAfter = realm.objects(Task.self).count
                }
                it("won't add it to the realm") {
                    expect(totalObjectsBefore) == totalObjectsAfter
                }
                it("won't use a logger") {
                    expect(RealmNotification.sharedInstance.loggers.count) == 0
                }
                it("clean") {
                    self.cleanLoggers()
                }
            }
            
            context("the model has primaryKey but the dictionary doesn't") {
                var object: [String : Any]!
                var totalObjectsBefore: Int!
                var totalObjectsAfter: Int!
                beforeEach {
                    self.cleanLoggers()
                    totalObjectsBefore = realm.objects(Task.self).count
                    object = ["name" : "hola"]
                    try! realm.write {
                        realm.createNotified(Task.self, value: object, update: true)
                    }
                    totalObjectsAfter = realm.objects(Task.self).count
                }
                it("won't add it to the realm") {
                    expect(totalObjectsBefore) == totalObjectsAfter
                }
                it("won't use a logger") {
                    expect(RealmNotification.sharedInstance.loggers.count) == 0
                }
                it("clean") {
                    self.cleanLoggers()
                }
            }
        }
        
        describe("deleteNotified (array)") {
            var refetchedTask: Task?

            beforeEach {
                refetchedTask = realm.object(ofType: Task.self, forPrimaryKey: 1500)
                try! realm.write {
                    realm.deleteNotified([refetchedTask!])
                }
            }
            it("object in DB is invalidated") {
                expect(refetchedTask?.isInvalidated).to(beTruthy())
            }
            afterEach {
                self.cleanLoggers()
            }
        }
        
        describe("execute") {
            var request: RealmRequest<Task>!
            var result: Task!
            beforeEach {
                try! realm.write {
                    let task = Task()
                    task.id = 161123123
                    realm.addNotified([task])
                }
                let predicate = NSPredicate(format: "id == %d", 161123123)
                request = RealmRequest<Task>(predicate: predicate, realm: realm, sortDescriptors: [])
                result = realm.execute(request).toArray().first!
            }
            it("returns the correct element") {
                expect(result.id) == 161123123
            }
            afterEach {
                try! realm.write {
                    realm.delete(result)
                }
                self.cleanLoggers()
            }
        }
        describe("getMirror()") {
            context("If the object has an optional nil value") {
                var mirrored: Dummy!
                var initial: Dummy!
                beforeEach {
                    initial = Dummy()
                    initial.id = 4
                    mirrored = initial.getMirror()
                }
                it("Should have a nil 'optionalNilValue'") {
                    expect(mirrored.optionalNilValue).to(beNil())
                    expect(mirrored.id).to(equal(4))
                }
            }
        }
    }
}
