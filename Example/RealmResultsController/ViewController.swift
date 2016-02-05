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
    var rrc: RealmResultsController<CarObject, CarObject>?
    var realm: Realm!
    let button: UIButton = UIButton()
    
    lazy var realmPath: String = {
        guard let doc = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory,
                        NSSearchPathDomainMask.UserDomainMask, true).first else { return "" }
        let custom = doc.stringByAppendingString("/example.realm")
        return custom
    }()

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let _ = NSClassFromString("XCTest") {
            return
        }
    
        realm = try! Realm()
        
        try! realm.write {
            self.realm.deleteAll()
        }
        
        populateDB()
        rrc = CarObject.resultsController()
        rrc!.delegate = self
        rrc!.performFetch()
        setupSubviews()
        addInBackground()
    }
//
    func populateDB() {
        let carsDictionaries = [
            [
                "pictureURL" : "http://myURL",
                "modelName" : "Model S1",
                "manudacturerName" : "Tesla",
                "userName" : "poolqf",
                "href" : "1"
            ],
            [
                "pictureURL" : "http://myURL",
                "modelName" : "Model S2",
                "manudacturerName" : "Tesla",
                "userName" : "poolqf",
                "href" : "2"
            ],
            [
                "pictureURL" : "http://myURL",
                "modelName" : "Model S3",
                "manufacturerName" : "Tesla",
                "userName" : "poolqf",
                "href" : "3"
            ],
            [
                "pictureURL" : "http://myURL",
                "modelName" : "Model S4",
                "manudacturerName" : "Tesla",
                "userName" : "poolqf",
                "href" : "4"
            ],
            [
                "pictureURL" : "http://myURL",
                "modelName" : "Model S5",
                "manudacturerName" : "Tesla",
                "userName" : "poolqf",
                "href" : "5"
            ],
            [
                "pictureURL" : "http://myURL",
                "modelName" : "Model S6",
                "manudacturerName" : "Tesla",
                "userName" : "poolqf",
                "href" : "6"
            ]
        ]
        
        let startDate: NSDate = NSDate(timeIntervalSince1970: 100)
        let untilDate: NSDate = NSDate(timeIntervalSince1970: 2000)
        let location = "My place"
        
        let carsObjects : [CarObject] = carsDictionaries.map({CarObject(value: $0)})
        
        let query : QueryModel = QueryModel(startDate: startDate, untilDate: untilDate, location: location)
        
        carsObjects.forEach({$0.searchQueries.append(query)})
        
        query.cars.appendContentsOf(carsObjects)
        
        let realm : Realm = try! Realm()
        
        try! realm.write({ () -> Void in
            realm.addNotified(carsObjects, update: true)
        })
    }
    
    func addInBackground() {
        
        let queue: dispatch_queue_t = dispatch_queue_create("label", nil)
        dispatch_async(queue) {
            autoreleasepool {
                let realm = try! Realm()
                try! realm.write {
                    let obj = realm.objectForPrimaryKey(CarObject.self, key: "6")
                    
                    let update = [
                        "pictureURL" : "http://myURL",
                        "modelName" : "Model S6Updated",
                        "manudacturerName" : "Tesla",
                        "userName" : "poolqf",
                        "href" : "6"
                    ]
                    let updateObject = CarObject(value: update)
                    realm.addNotified(updateObject, update: true)
                    realm.deleteNotified(obj!)
                }
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
        
        
        
        
//        let projectID = Int(arc4random_uniform(3))
//        
//        let queue: dispatch_queue_t = dispatch_queue_create("label", nil)
//        dispatch_async(queue) {
//            autoreleasepool {
//                let realm = try! Realm(path: self.realmPath)
//                try! realm.write {
//                    let task = TaskModelObject()
//                    task.id = Int(arc4random_uniform(9999))
//                    task.name = "Task-\(task.id)"
//                    task.projectID = projectID
//                    let user = UserObject()
//                    user.id = task.id
//                    user.name = String(Int(arc4random_uniform(1000)))
//                    task.user = user
//                    realm.addNotified(task, update: true)
//                }
//            }
//        }
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
        let car = rrc!.objectAt(indexPath)
        cell?.textLabel?.text = car.manufacturerName + " :: " + car.modelName
        return cell!
    }
    
//    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
//        let task = rrc!.objectAt(indexPath)
//        try! realm.write {
//            let model = self.realm.objectForPrimaryKey(TaskModelObject.self, key: task.id)!
//            self.realm.deleteNotified(model)
//        }
//    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
//        let keyPath: String = rrc!.sections[section].keyPath
//        return "ProjectID \(keyPath)"
        return "HEADER SECTION \(section)"
    }
    
    func tableView(tableView: UITableView, titleForFooterInSection section: Int) -> String? {
//        return section == 2 ? "Tap on a row to delete it" : nil
        return "FOOTER SECTION \(section)"
    }
    
    // MARK: RealmResult
    
    func willChangeResults(controller: AnyObject) {
        print("🎁 WILLChangeResults")
        tableView.beginUpdates()
    }
    
    func didChangeObject<U>(controller: AnyObject, object: U, oldIndexPath: NSIndexPath, newIndexPath: NSIndexPath, changeType: RealmResultsChangeType) {
//        print("🎁 didChangeObject '\((object as! TaskModelObject).name)' from: [\(oldIndexPath.section):\(oldIndexPath.row)] to: [\(newIndexPath.section):\(newIndexPath.row)] --> \(changeType)")
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
    
    func didChangeSection<U>(controller: AnyObject, section: RealmSection<U>, index: Int, changeType: RealmResultsChangeType) {
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