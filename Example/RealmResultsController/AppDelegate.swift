
//
//  AppDelegate.swift
//  RealmResultsController
//
//  Created by Pol Quintana on 5/8/15.
//  Copyright © 2015 Redbooth. All rights reserved.
//

import UIKit
import RealmSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
//        generateDB()
        return true
    }
}

//func generateDB() {
//    let realm = try! Realm()
//    realm.write {
//        for i in 0...1000 {
//            let task = Task()
//            task.id = i
//            task.name = randomStringWithLength(10)
//            task.resolved = arc4random_uniform(2) % 2 == 0
//            task.projectID = Int(arc4random_uniform(3))
//            task.user.id = i + 99999
//            task.user.name = randomStringWithLength(10)
//            
//            let user = User()
//            user.id = i
//            user.name = randomStringWithLength(10)
//            user.avatarURL = "http://www.gravatar.com/" + randomStringWithLength(5)
//            
//            let project = Project()
//            project.id = i
//            project.name = randomStringWithLength(10)
//            project.projectDrescription = randomStringWithLength(20)
//            
//            realm.add(task)
//            realm.add(user)
//            realm.add(project)
//        }
//    }
//}
//
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

