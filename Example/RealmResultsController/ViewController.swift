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
    let realm: Realm = try! Realm()
    let button: UIButton = UIButton()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        realm.write {
            self.realm.deleteAll()
        }
        populateDB()
        let request = RealmRequest<TaskModel>(predicate: NSPredicate(value: true), realm: realm, sortDescriptors: [SortDescriptor(property: "projectID")  , SortDescriptor(property: "name")])
        rrc = RealmResultsController<TaskModel, Task>(request: request, sectionKeyPath: "projectID", mapper: Task.map)
        rrc!.delegate = self
        rrc!.performFetch()
        setupSubviews()
    }
    
    func populateDB() {
        realm.write {
            for i in 0...9 {
                let task = TaskModel()
                task.id = i
                task.name = "Task-\(i)"
                task.projectID = Int(arc4random_uniform(2))
                self.realm.add(task)
            }
        }
    }
    
    func setupSubviews() {
        tableView.frame = view.frame
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
        
        button.frame = CGRectMake(view.frame.width - 50, 20, 30, 30)
        button.backgroundColor = UIColor.redColor()
        button.titleLabel?.text = "Add"
        button.addTarget(self, action: "addNewObject", forControlEvents: .TouchUpInside)
        view.addSubview(button)
    }
    
    func addNewObject() {
        realm.write {
            let task = TaskModel()
            //            let array = [1,10,100,101,102,103,104,105,106,107,108,109]
            //            let array2 = ["A","B","C","D","E","F","G","H","I","J","K"]
            task.id = Int(arc4random_uniform(1000))
            task.projectID = Int(arc4random_uniform(3))
            task.name = "Task-\(task.id)"
            self.realm.addNotified(task, update: true)
        }
    }
    
    
    // MARK: Table view protocols
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        print("sections: \(rrc!.numberOfSections)")
        return rrc!.numberOfSections
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        print("number: \(rrc!.numberOfObjectsAt(section))")
        return rrc!.numberOfObjectsAt(section)
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("celltask")
        if cell == nil {
            cell = UITableViewCell(style: .Default, reuseIdentifier: "celltask")
        }
        let task = rrc!.objectAt(indexPath)
        print("task project: \(task.projectID)")
        cell?.textLabel?.text = task.name + " :: " + String(task.projectID)
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
        return rrc?.sections[section].keyPath
    }
    
    // MARK: RealmResult
    
    func willChangeResults(controller: AnyObject) {
        print("💚💚💚💚")
        tableView.beginUpdates()
    }
    
    func didChangeObject<U>(object: U, controller: AnyObject, atIndexPath: NSIndexPath, newIndexPath: NSIndexPath, changeType: RealmResultsChangeType) {
        print("💜 DID CHANGE: \(changeType) at indexPath \(newIndexPath.row)")
        switch changeType {
        case .Delete:
            tableView.deleteRowsAtIndexPaths([newIndexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
            break
        case .Insert:
            tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
            break
        case .Move:
            tableView.deleteRowsAtIndexPaths([atIndexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
            tableView.insertRowsAtIndexPaths([newIndexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
            break
        case .Update:
            tableView.reloadRowsAtIndexPaths([newIndexPath], withRowAnimation: UITableViewRowAnimation.Automatic)
            break
        }
    }
    
    func didChangeSection<U>(section: RealmSection<U>, controller: AnyObject, index: Int, changeType: RealmResultsChangeType) {
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
        tableView.endUpdates()
        print("❤️❤️❤️❤️❤️")
    }
    
}