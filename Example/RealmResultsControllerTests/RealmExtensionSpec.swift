//
//  RealmExtensionSpec.swift
//  RealmResultsController
//
//  Created by Isaac Roldan on 7/8/15.
//  Copyright © 2015 Redbooth. All rights reserved.
//

import Foundation
import Quick
import Nimble
import RealmSwift



class CacheSpec: QuickSpec {
    
    override func spec() {
        
        var realm: Realm!
        
        beforeSuite {
            RealmTestHelper.loadRealm()
            realm = try! Realm()
        }
    

    }
}