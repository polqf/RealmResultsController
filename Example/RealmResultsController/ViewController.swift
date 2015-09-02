//
//  ViewController.swift
//  RealmResultsController
//
//  Created by Pol Quintana on 5/8/15.
//  Copyright © 2015 Redbooth.
//

import Foundation
import UIKit
import RealmSwift
import RealmResultsController

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, RealmResultsControllerDelegate {
    
    let tableView: UITableView = UITableView(frame: CGRectZero, style: .Grouped)
    var rrc: RealmResultsController<TaskModelObject, TaskObject>?
    var realm: Realm!
    let button: UIButton = UIButton()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let _ = NSClassFromString("XCTest") {
            return
        }
        realm = try! Realm(path: NSBundle.mainBundle().resourcePath! + "/example.realm")
        try! realm.write {
            self.realm.deleteAll()
        }
        populateDB()
        let request = RealmRequest<TaskModelObject>(predicate: NSPredicate(value: true), realm: realm, sortDescriptors: [SortDescriptor(property: "projectID")  , SortDescriptor(property: "name")])
        rrc = try! RealmResultsController<TaskModelObject, TaskObject>(request: request, sectionKeyPath: "projectID", mapper: TaskObject.map)
        rrc!.delegate = self
        rrc!.performFetch()
        setupSubviews()
    }

    func populateDB() {
        try! realm.write {
            for i in 1...2 {
                let task = TaskModelObject()
                task.id = i
                task.name = "Task-\(i)"
                task.projectID = 0
                let user = UserObject()
                user.id = i
                user.name = String(Int(arc4random_uniform(1000)))
                task.user = user
                self.realm.add(task)
            }
            for i in 3...4 {
                let task = TaskModelObject()
                task.id = i
                task.name = "Task-\(i)"
                task.projectID = 1
                let user = UserObject()
                user.id = i
                user.name = String(Int(arc4random_uniform(1000)))
                task.user = user
                self.realm.add(task)
            }
            for i in 5...6 {
                let task = TaskModelObject()
                task.id = i
                task.name = "Task-\(i)"
                task.projectID = 2
                let user = UserObject()
                user.id = i
                user.name = String(Int(arc4random_uniform(1000)))
                task.user = user
                self.realm.add(task)
            }
        }
    }

    func setupSubviews() {
        let height: CGFloat = 50
        button.frame = CGRectMake(0, view.frame.height - height, view.frame.width, height)
        button.backgroundColor = UIColor.redColor()
        button.setTitle("Add Row", forState: .Normal)
        button.addTarget(self, action: "addNewObject", forControlEvents: .TouchUpInside)
        view.addSubview(button)

        tableView.frame = CGRectMake(0, 0, view.frame.width, view.frame.height - height)
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
    }

    func addNewObject() {
        let projectID = Int(arc4random_uniform(3))
        try! realm.write {
            let task = TaskModelObject()
            task.id = Int(arc4random_uniform(9999))
            task.name = "Task-\(task.id)"
            task.projectID = projectID
            let user = UserObject()
            user.id = task.id
            user.name = String(Int(arc4random_uniform(1000)))
            task.user = user
            self.realm.addNotified(task, update: true)
        }
    }
    
    
    // MARK: Table view protocols
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return rrc!.numberOfSections
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rrc!.numberOfObjectsAt(section)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("celltask")
        if cell == nil {
            cell = UITableViewCell(style: .Default, reuseIdentifier: "celltask")
        }
        let task = rrc!.objectAt(indexPath)
        cell?.textLabel?.text = task.name + " :: " + String(task.projectID)
        return cell!
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let task = rrc!.objectAt(indexPath)
        try! realm.write {
            let model = self.realm.objectForPrimaryKey(TaskModelObject.self, key: task.id)!
            self.realm.deleteNotified(model)
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let keyPath: String = rrc!.sections[section].keyPath
        return "ProjectID \(keyPath)"
    }
    
    func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return section == 2 ? "Tap on a row to delete it" : nil
    }
    
    // MARK: RealmResult
    
    func willChangeResults(controller: AnyObject) {
        print("🎁 WILLChangeResults")
        tableView.beginUpdates()
    }
    
    func didChangeObject<U>(object: U, controller: AnyObject, oldIndexPath: NSIndexPath, newIndexPath: NSIndexPath, changeType: RealmResultsChangeType) {
        print("🎁 didChangeObject '\((object as! TaskModelObject).name)' from: [\(oldIndexPath.section):\(oldIndexPath.row)] to: [\(newIndexPath.section):\(newIndexPath.row)] --> \(changeType)")
        switch changeType {
        case .Delete:
            tableView.deleteRowsAtIndexPaths([newIndexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
            break
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
            break
        case .Move:
            tableView.deleteRowsAtIndexPaths([oldIndexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
            tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
            break
        case .Update:
            tableView.reloadRowsAtIndexPaths([newIndexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
            break
        }
    }
    
    func didChangeSection<U>(section: RealmSection<U>, controller: AnyObject, index: Int, changeType: RealmResultsChangeType) {
        print("🎁 didChangeSection \(index) --> \(changeType)")
        switch changeType {
        case .Delete:
            tableView.deleteSections(NSIndexSet(index: index), withRowAnimation: UITableViewRowAnimation.Automatic)
            break
        case .Insert:
            tableView.insertSections(NSIndexSet(index: index), withRowAnimation: UITableViewRowAnimation.Automatic)
            break
        default:
            break
        }
    }
    
    func didChangeResults(controller: AnyObject) {
        print("🎁 DIDChangeResults")
        tableView.endUpdates()
    }
    
}