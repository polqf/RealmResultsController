//
//  ViewControllerSpec.swift
//  RealmResultsController
//
//  Created by Isaac Roldan on 13/8/15.
//  Copyright © 2015 Redbooth. All rights reserved.
//

import Foundation
import Quick
import Nimble
import RealmSwift

@testable import RealmResultsController


/// Note: Specs created only to reach 100% coverage. 
/// Until Xcode lets you ignore View files in the coverage
class ViewControllerSpec: QuickSpec {
    
    override func spec() {
        var vc: ViewController!
        var realm: Realm!
        
        beforeSuite {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            vc = storyboard.instantiateViewControllerWithIdentifier("vc") as! ViewController
            vc.viewDidLoad()
            realm = vc.realm
        }
        
        describe("addNewObject()") {
            var objects: [TaskModel]!
            beforeEach {
                realm.write {
                    realm.deleteAll()
                }
                vc.addNewObject()
                objects = realm.objects(TaskModel.self).toArray(TaskModel.self)
            }
            it("it is not nil") {
                expect(objects.count).to(equal(1))
            }
            
        }
        describe("addNewObject()") {
            var oldObjects: [TaskModel]!
            var objects: [TaskModel]!
            beforeEach {
                realm.write {
                    realm.deleteAll()
                }
                vc.populateDB()
                oldObjects = realm.objects(TaskModel.self).toArray(TaskModel.self)
                vc.tableView(vc.tableView, didSelectRowAtIndexPath: NSIndexPath(forRow: 0, inSection: 0))
                objects = realm.objects(TaskModel.self).toArray(TaskModel.self)
            }
            it("Should have 1 new object") {
                expect(objects.count).to(equal(oldObjects.count - 1))
            }
            
        }
        describe("tableView delegate methods") {
            let task = TaskModel()
            let indexPath = NSIndexPath(forRow: 1, inSection: 1)
            beforeEach {
                vc.willChangeResults(vc.rrc!)
                vc.didChangeObject(task, controller: vc.rrc!, oldIndexPath: indexPath, newIndexPath: indexPath, changeType: RealmResultsChangeType.Delete)
                vc.didChangeObject(task, controller: vc.rrc!, oldIndexPath: indexPath, newIndexPath: indexPath, changeType: RealmResultsChangeType.Insert)
                vc.didChangeObject(task, controller: vc.rrc!, oldIndexPath: indexPath, newIndexPath: indexPath, changeType: RealmResultsChangeType.Move)
                vc.didChangeObject(task, controller: vc.rrc!, oldIndexPath: indexPath, newIndexPath: indexPath, changeType: RealmResultsChangeType.Update)
                vc.didChangeSection(vc.rrc!.sections[0], controller: vc.rrc!, index: 0, changeType: RealmResultsChangeType.Insert)
                vc.didChangeSection(vc.rrc!.sections[0], controller: vc.rrc!, index: 0, changeType: RealmResultsChangeType.Delete)
                vc.didChangeSection(vc.rrc!.sections[0], controller: vc.rrc!, index: 0, changeType: RealmResultsChangeType.Move)
                vc.didChangeResults(vc.rrc!)
            }
            it("Did just called all the delegate methods") {
                
            }
        }
    }
}