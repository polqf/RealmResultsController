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
    
    override func viewDidAppear(animated: Bool) {
        addNewObject()
    }
    
    func populateDB() {
        realm.write {
            for i in 0...4 {
                let task = TaskModel()
                task.id = i
                task.name = "Task-\(i)"
                task.projectID = Int(arc4random_uniform(2))
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
            let task = TaskModel()
            task.id = Int(arc4random_uniform(5))
            task.projectID = Int(arc4random_uniform(3))
            task.name = "Task-\(task.id)"
            let user = User()
            user.name = String(Int(arc4random_uniform(1000)))
            user.id = Int(arc4random_uniform(1000))
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
        print("🎁 willChangeResults")
        tableView.beginUpdates()
    }
    
    func didChangeObject<U>(object: U, controller: AnyObject, oldIndexPath: NSIndexPath, newIndexPath: NSIndexPath, changeType: RealmResultsChangeType) {
        print("🎁 didChangeObject oldIndex:\(oldIndexPath) toIndex:\(newIndexPath) changeType:\(changeType)")
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
        print("🎁 didChangeSection index:\(index) changeType:\(changeType)")
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
        print("🎁 didChangeResults")
        tableView.endUpdates()
    }
    
}