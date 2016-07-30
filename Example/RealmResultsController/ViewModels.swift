//
//  testmodels.swift
//  RealmResultsController
//
//  Created by Isaac Roldan on 6/8/15.
//  Copyright © 2015 Redbooth.
//

import Foundation
import RealmSwift


class TaskObject: RealmSwift.Object {
    dynamic var id = 0
    dynamic var name = ""
    dynamic var resolved = false
    dynamic var projectID = 0
    dynamic var user: UserObject?
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    lazy var something: Bool = {
        true
    }()
    
    static func map(_ model: TaskModelObject) -> TaskObject {
        let task = TaskObject()
        task.id = model.id
        task.name = model.name
        task.resolved = model.resolved
        task.projectID = model.projectID
        return task
    }
    
    static func mapTask(_ taskModel: TaskObject) -> TaskModelObject {
        let task = TaskModelObject()
        task.id = taskModel.id
        task.name = taskModel.name
        task.resolved = taskModel.resolved
        task.projectID = taskModel.projectID
        return task
    }
}

class TaskModelObject: RealmSwift.Object {
    dynamic var id = 0
    dynamic var name = ""
    dynamic var resolved = false
    dynamic var projectID = 0
    dynamic var user: UserObject?
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    lazy var something: Bool = {
        true
    }()
}

class UserObject: RealmSwift.Object {
    dynamic var id = 0
    dynamic var name = ""
    dynamic var avatarURL = ""
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

class ProjectObject: RealmSwift.Object {
    dynamic var id = 0
    dynamic var name = ""
    dynamic var projectDrescription = ""
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

class DummyObject: RealmSwift.Object {
    dynamic var id: Int = 0
    dynamic var optionalNilValue: ProjectObject?
}
