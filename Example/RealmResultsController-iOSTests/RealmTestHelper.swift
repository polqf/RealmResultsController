//
//  RealmTestHelper.swift
//  RealmResultsController
//
//  Created by Pol Quintana on 6/8/15.
//  Copyright © 2015 Redbooth.
//

import Foundation
import RealmSwift

struct RealmTestHelper {
    static var firstTime = true
    
    static func loadRealm() {
        if !firstTime { return }
        firstTime = false
        
        let defaultRealmPath = Realm.Configuration.defaultConfiguration.fileURL!.absoluteString
            .replacingOccurrences(of: "file:///", with: "/")
        let bundleReamPath: String? = Bundle.main.resourcePath! + "/test.realm"
        
        if FileManager.default.fileExists(atPath: defaultRealmPath) {
            try! FileManager.default.removeItem(atPath: defaultRealmPath)
        }
        try! FileManager.default.copyItem(atPath: bundleReamPath!, toPath: defaultRealmPath)
    }
}

