//
//  RealmExtensionSpec.swift
//  RealmResultsController
//
//  Created by Isaac Roldan on 7/8/15.
//  Copyright © 2015 Redbooth. All rights reserved.
//

import Foundation
import Quick
import Nimble
import RealmSwift

@testable import RealmResultsController

class Dummy: Object {
    dynamic var id: Int = 0
}


class RealmExtensionSpec: QuickSpec {
    
    func cleanLoggers() {
        RealmNotification.sharedInstance.loggers = []
    }
    
    override func spec() {
        
        var realm: Realm!
        var taskToTest: Task?

        beforeSuite {
            realm = Realm(inMemoryIdentifier: "testingRealm")
            taskToTest = Task()
            taskToTest!.id = 1500
            taskToTest!.name = "testingName1"
            realm.write {
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
                    
                    fetchedTask = realm.objectForPrimaryKey(Task.self, key: 1)
                    
                    myTask = Task()
                    myTask!.id = 1
                    myTask!.name = "test"
                    realm.write {
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
                    realm.write {
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
                realm.write {
                    realm.createNotified(Task.self, value: ["id":1501, "name": "testingName2"], update: true)
                }
                refetchedTask = realm.objectForPrimaryKey(Task.self, key: 1501)
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
                var myTask: [String: AnyObject]!
                var fetchedTask: Task!
                beforeEach {
                    self.cleanLoggers()
                    myTask = ["name": "hola", "id": 1501, "resolved": 1]
                    realm.write {
                        realm.createNotified(Task.self, value: myTask, update: true)
                    }
                    fetchedTask = realm.objectForPrimaryKey(Task.self, key: 1501)

                }
                it("trying to add the same object again, will update it") {
                    expect(fetchedTask.name) == "hola"
                }
                it("clean") {
                    self.cleanLoggers()
                }
            }

            
            context("the Model does not have primaryKey") {
                var object: [String: AnyObject]!
                var totalObjectsBefore: Int!
                var totalObjectsAfter: Int!
                beforeEach {
                    self.cleanLoggers()
                    totalObjectsBefore = realm.objects(Task).count
                    object = ["name": "hola"]
                    realm.write {
                        realm.createNotified(Dummy.self, value: object, update: true)
                    }
                    totalObjectsAfter = realm.objects(Task).count
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
                var object: [String: AnyObject]!
                var totalObjectsBefore: Int!
                var totalObjectsAfter: Int!
                beforeEach {
                    self.cleanLoggers()
                    totalObjectsBefore = realm.objects(Task).count
                    object = ["name": "hola"]
                    realm.write {
                        realm.createNotified(Task.self, value: object, update: true)
                    }
                    totalObjectsAfter = realm.objects(Task).count
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
            var refetchedTask: Task!

            beforeEach {
                refetchedTask = realm.objectForPrimaryKey(Task.self, key: 1500)
                realm.write {
                    realm.deleteNotified([refetchedTask])
                }
            }
            it("object in DB is invalidated") {
                expect(refetchedTask.invalidated).to(beTruthy())
            }
            afterEach {
                self.cleanLoggers()
            }
        }
        
        
        describe("execute") {
            var request: RealmRequest<Task>!
            var result: Task!
            beforeEach {
                realm.write {
                    let task = Task()
                    task.id = 1600
                    realm.addNotified([task])
                }
                let predicate = NSPredicate(format: "id == %d", 1600)
                request = RealmRequest<Task>(predicate: predicate, realm: realm, sortDescriptors: [])
                result = realm.execute(request).toArray(Task.self).first!
            }
            it("returns the correct element") {
                expect(result.id) == 1600
            }
            afterEach {
                realm.write {
                    realm.delete(result)
                }
                self.cleanLoggers()
            }
        }
    }
}