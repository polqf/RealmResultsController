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
    dynamic var user: User = User()
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    static func map(model: TaskModel) -> Task {
        let task = Task()
        task.id = model.id
        task.name = model.name
        task.resolved = model.resolved
        task.projectID = model.projectID
        task.user = model.user
        return task
    }
}

class TaskModel: Object {
    dynamic var id = 0
    dynamic var name = ""
    dynamic var resolved = false
    dynamic var projectID = 0
    dynamic var user: User = User()
    
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

//func randomStringWithLength (len : Int) -> String {
//    
//    let letters : String = "abcdefghijklmnopqrstuvwxyz"
//    var randomString: String = ""
//    
//    for (var i=0; i < len; i++){
//        let length = UInt32 (letters.characters.count)
//        let rand = Int(arc4random_uniform(length))
//        randomString += letters[rand]
//    }
//    
//    return randomString
//}
//
//
//extension String {
//    
//    subscript (i: Int) -> Character {
//        return self[advance(self.startIndex, i)]
//    }
//    
//    subscript (i: Int) -> String {
//        return String(self[i] as Character)
//    }
//    
//    subscript (r: Range<Int>) -> String {
//        return substringWithRange(Range(start: advance(startIndex, r.startIndex), end: advance(startIndex, r.endIndex)))
//    }
//}

