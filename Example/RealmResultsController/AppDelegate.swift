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
        // Override point for customization after application launch.
//        generateDB()        
        return true
    }
//
//    func applicationWillResignActive(application: UIApplication) {
//        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
//        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
//    }
//
//    func applicationDidEnterBackground(application: UIApplication) {
//        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
//        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
//    }
//
//    func applicationWillEnterForeground(application: UIApplication) {
//        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
//    }
//
//    func applicationDidBecomeActive(application: UIApplication) {
//        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
//    }
//
//    func applicationWillTerminate(application: UIApplication) {
//        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
//    }
//    
//    
//    func generateDB() {
//        let realm = try! Realm()
//        realm.write {
//            for i in 0...1000 {
//                let task = Task()
//                task.id = i
//                task.name = randomStringWithLength(10)
//                task.resolved = arc4random_uniform(2) % 2 == 0
//                task.projectID = Int(arc4random_uniform(3))
//
//                let taskModel = TaskModel()
//                taskModel.id = i
//                taskModel.name = randomStringWithLength(10)
//                taskModel.resolved = arc4random_uniform(2) % 2 == 0
//                taskModel.projectID = Int(arc4random_uniform(3))
//
//                let user = User()
//                user.id = i
//                user.name = randomStringWithLength(10)
//                user.avatarURL = "http://www.gravatar.com/" + randomStringWithLength(5)
//                
//                let project = Project()
//                project.id = i
//                project.name = randomStringWithLength(10)
//                project.projectDrescription = randomStringWithLength(20)
//                
//                realm.add(task)
//                realm.add(taskModel)
//                realm.add(user)
//                realm.add(project)
//            }
//        }
//    }
}
