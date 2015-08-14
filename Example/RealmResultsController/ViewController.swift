//
//  ViewController.swift
//  RealmResultsController
//
//  Created by Pol Quintana on 5/8/15.
//  Copyright © 2015 Redbooth. All rights reserved.
//

import UIKit

import UIKit
import RealmSwift

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, RealmResultsControllerDelegate {
    
    let tableView: UITableView = UITableView(frame: CGRectZero, style: .Grouped)
    var rrc: RealmResultsController<TaskModel, Task>?
    var realm: Realm!
    let button: UIButton = UIButton()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        realm = try! Realm(path: NSBundle.mainBundle().resourcePath! + "/example.realm")
        realm.write {
            self.realm.deleteAll()
        }
        populateDB()
        let request = RealmRequest<TaskModel>(predicate: NSPredicate(value: true), realm: realm, sortDescriptors: [SortDescriptor(property: "projectID")  , SortDescriptor(property: "name")])
        do {
            rrc = try RealmResultsController<TaskModel, Task>(request: request, sectionKeyPath: "projectID", mapper: Task.map)
        } catch {
            print(error)
        }
        rrc!.delegate = self
        rrc!.performFetch()
        setupSubviews()
    }

    func populateDB() {
        realm.write {
            for i in 1...3 {
                let task = TaskModel()
                task.id = i
                task.name = "Task-\(i)"
                task.projectID = 1
                let user = User()
                user.id = i
                user.name = String(Int(arc4random_uniform(1000)))
                task.user = user
                self.realm.add(task)
            }
            for i in 10...12 {
                let task = TaskModel()
                task.id = i
                task.name = "Task-\(i)"
                task.projectID = 3
                let user = User()
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
        realm.write {
            
            let task4 = self.realm.objectForPrimaryKey(TaskModel.self, key: 10)
            let task5 = self.realm.objectForPrimaryKey(TaskModel.self, key: 3)
            let task6 = self.realm.objectForPrimaryKey(TaskModel.self, key: 11)
            self.realm.deleteNotified(task4!)
            self.realm.deleteNotified(task5!)
            self.realm.deleteNotified(task6!)
            
            
            let task = TaskModel()
            task.id = 2
            task.projectID = 0
//            task.name = String(Int(arc4random_uniform(1000))) + "Task-\(task.id)"
            task.name = "Task-\(task.id)"
            self.realm.addNotified(task, update: true)
//            
            let task2 = TaskModel()
            task2.id = 1
            task2.projectID = 2
//            task2.name = String(Int(arc4random_uniform(1000))) + "Task-\(task2.id)"
            task2.name = "Task-\(task2.id)"
            self.realm.addNotified(task2, update: true)
            
            let task3 = TaskModel()
            task3.id = 10
            task3.projectID = 6
//            task3.name = String(Int(arc4random_uniform(1000))) + "Task-\(task3.id)"
            task3.name = "Task-\(task3.id)"
            self.realm.addNotified(task3, update: true)  
        }
    }
    
    
    // MARK: Table view protocols
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return rrc!.numberOfSections
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("🎀 Section: \(section): \(rrc!.numberOfObjectsAt(section))")
        return rrc!.numberOfObjectsAt(section)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("celltask")
        if cell == nil {
            cell = UITableViewCell(style: .Default, reuseIdentifier: "celltask")
        }
        let task = rrc!.objectAt(indexPath)
        
        let userName = task.user == nil ? "user" : task.user!.name
        cell?.textLabel?.text = task.name + " :: " + String(task.projectID) + "::" + userName
        return cell!
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let task = rrc!.objectAt(indexPath)
        realm.write {
            let model = self.realm.objectForPrimaryKey(TaskModel.self, key: task.id)
            guard let m = model else { return }
            self.realm.deleteNotified(m)
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let keyPath: String = rrc!.sections[section].keyPath
        return "ProjectID \(keyPath)"
    }
    
    // MARK: RealmResult
    
    func willChangeResults(controller: AnyObject) {
        print("🎁 WILL")
        tableView.beginUpdates()
    }
    
    func didChangeObject<U>(object: U, controller: AnyObject, oldIndexPath: NSIndexPath, newIndexPath: NSIndexPath, changeType: RealmResultsChangeType) {
        print("🎁 didChangeObject \((object as! TaskModel).name) from: [\(oldIndexPath.section):\(oldIndexPath.row)] to: [\(newIndexPath.section):\(newIndexPath.row)] --> \(changeType)")
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
        print("🎁 DID")
        tableView.endUpdates()
    }
    
}