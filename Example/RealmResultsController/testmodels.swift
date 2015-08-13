//
//  testmodels.swift
//  RealmResultsController
//
//  Created by Isaac Roldan on 6/8/15.
//  Copyright © 2015 Redbooth. All rights reserved.
//

import Foundation
import RealmSwift


class Task: Object {
    dynamic var id = 0
    dynamic var name = ""
    dynamic var resolved = false
    dynamic var projectID = 0
    dynamic var user: User?
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    static func map(model: TaskModel) -> Task {
        let task = Task()
        task.id = model.id
        task.name = model.name
        task.resolved = model.resolved
        task.projectID = model.projectID
        return task
    }
    
    static func mapTask(taskModel: Task) -> TaskModel {
        let task = TaskModel()
        task.id = taskModel.id
        task.name = taskModel.name
        task.resolved = taskModel.resolved
        task.projectID = taskModel.projectID
        return task
    }
}

class TaskModel: Object {
    dynamic var id = 0
    dynamic var name = ""
    dynamic var resolved = false
    dynamic var projectID = 0
    dynamic var user: User?
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

class User: Object {
    dynamic var id = 0
    dynamic var name = ""
    dynamic var avatarURL = ""
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

class Project: Object {
    dynamic var id = 0
    dynamic var name = ""
    dynamic var projectDrescription = ""
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

class Dummy: Object {
    dynamic var id: Int = 0
    dynamic var optionalNilValue: Project?
}