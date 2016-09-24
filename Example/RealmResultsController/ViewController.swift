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

    let tableView: UITableView = UITableView(frame: CGRect.zero, style: .grouped)
    var rrc: RealmResultsController<TaskModelObject, TaskObject>?
    var realm: Realm!
    let button: UIButton = UIButton()

    lazy var realmConfiguration: Realm.Configuration = {
        guard let doc = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory,
                                                            FileManager.SearchPathDomainMask.userDomainMask, true).first else {
                                                                return Realm.Configuration.defaultConfiguration
        }
        let custom = doc + "/example.realm"
        return Realm.Configuration(fileURL: URL(string: custom))
    }()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let _ = NSClassFromString("XCTest") {
            return
        }

        realm = try! Realm(configuration: realmConfiguration)
        
        try! realm.write {
            self.realm.deleteAll()
        }
        populateDB()
        let request = RealmRequest<TaskModelObject>(predicate: NSPredicate(value: true), realm: realm, sortDescriptors: [RealmSwift.SortDescriptor(property: "projectID")  , RealmSwift.SortDescriptor(property: "name")])
        rrc = try! RealmResultsController<TaskModelObject, TaskObject>(request: request, sectionKeyPath: "projectID", mapper: TaskObject.map)
        rrc!.delegate = self
        rrc!.performFetch()
        setupSubviews()
        addInBackground()
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
    
    func addInBackground() {
        
        let queue: DispatchQueue = DispatchQueue(label: "label", attributes: [])
        queue.async {
            autoreleasepool {
                let realm = try! Realm(configuration: self.realmConfiguration)
                try! realm.write {
                    let task = TaskModelObject()
                    task.id = 12345
                    task.name = "Task-\(12345)"
                    task.projectID = 0
                    realm.addNotified(task, update: true)
                }
            }
        }
    }
    
    func setupSubviews() {
        let height: CGFloat = 50
        button.frame = CGRect(x: 0, y: view.frame.height - height, width: view.frame.width, height: height)
        button.backgroundColor = UIColor.red
        button.setTitle("Add Row", for: UIControlState())
        button.addTarget(self, action: #selector(addNewObject), for: .touchUpInside)
        view.addSubview(button)

        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height - height)
        tableView.delegate = self
        tableView.dataSource = self
        view.addSubview(tableView)
    }

    func addNewObject() {
        let projectID = Int(arc4random_uniform(3))
        
        let queue: DispatchQueue = DispatchQueue(label: "label", attributes: [])
        queue.async {
            autoreleasepool {
                let realm = try! Realm(configuration: self.realmConfiguration)
                try! realm.write {
                    let task = TaskModelObject()
                    task.id = Int(arc4random_uniform(9999))
                    task.name = "Task-\(task.id)"
                    task.projectID = projectID
                    let user = UserObject()
                    user.id = task.id
                    user.name = String(Int(arc4random_uniform(1000)))
                    task.user = user
                    realm.addNotified(task, update: true)
                }
            }
        }
    }
    
    
    // MARK: Table view protocols
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return rrc!.numberOfSections
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rrc!.numberOfObjects(at: section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "celltask")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "celltask")
        }
        let task = rrc!.object(at: indexPath)
        cell?.textLabel?.text = task.name + " :: " + String(task.projectID)
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let task = rrc!.object(at: indexPath)
        try! realm.write {
            let model = self.realm.object(ofType: TaskModelObject.self, forPrimaryKey: task.id)!
            self.realm.deleteNotified(model)
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let keyPath: String = rrc!.sections[section].keyPath
        return "ProjectID \(keyPath)"
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return section == 2 ? "Tap on a row to delete it" : nil
    }
    
    // MARK: RealmResult
    
    func willChangeResults(_ controller: AnyObject) {
        print("🎁 WILLChangeResults")
        tableView.beginUpdates()
    }
    
    func didChangeObject<U>(_ controller: AnyObject, object: U, oldIndexPath: IndexPath, newIndexPath: IndexPath, changeType: RealmResultsChangeType) {
        print("🎁 didChangeObject '\((object as! TaskModelObject).name)' from: [\(oldIndexPath.section):\(oldIndexPath.row)] to: [\(newIndexPath.section):\(newIndexPath.row)] --> \(changeType)")
        switch changeType {
        case .Delete:
            tableView.deleteRows(at: [newIndexPath], with: UITableViewRowAnimation.automatic)
            break
        case .Insert:
            tableView.insertRows(at: [newIndexPath], with: UITableViewRowAnimation.automatic)
            break
        case .Move:
            tableView.deleteRows(at: [oldIndexPath], with: UITableViewRowAnimation.automatic)
            tableView.insertRows(at: [newIndexPath], with: UITableViewRowAnimation.automatic)
            break
        case .Update:
            tableView.reloadRows(at: [newIndexPath], with: UITableViewRowAnimation.automatic)
            break
        }
    }
    
    func didChangeSection<U>(_ controller: AnyObject, section: RealmSection<U>, index: Int, changeType: RealmResultsChangeType) {
        print("🎁 didChangeSection \(index) --> \(changeType)")
        switch changeType {
        case .Delete:
            tableView.deleteSections(IndexSet(integer: index), with: UITableViewRowAnimation.automatic)
            break
        case .Insert:
            tableView.insertSections(IndexSet(integer: index), with: UITableViewRowAnimation.automatic)
            break
        default:
            break
        }
    }
    
    func didChangeResults(_ controller: AnyObject) {
        print("🎁 DIDChangeResults")
        tableView.endUpdates()
    }
    
}
