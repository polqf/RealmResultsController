//
//  RealmTestHelper.swift
//  RealmResultsController
//
//  Created by Pol Quintana on 6/8/15.
//  Copyright © 2015 Redbooth. All rights reserved.
//

import Foundation
import RealmSwift

struct RealmTestHelper {
    static var firstTime = true
    
    static func loadRealm() {
        if !firstTime { return }
        firstTime = false
        
        let defaultRealmPath = Realm.Configuration.defaultConfiguration.path!
        let bundleReamPath: String? = NSBundle.mainBundle().resourcePath! + "/test.realm"
        
        if NSFileManager.defaultManager().fileExistsAtPath(defaultRealmPath) {
            try! NSFileManager.defaultManager().removeItemAtPath(defaultRealmPath)
        }
        try! NSFileManager.defaultManager().copyItemAtPath(bundleReamPath!, toPath: defaultRealmPath)
    }
}

