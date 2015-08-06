//
//  File.swift
//  RealmResultsController
//
//  Created by Isaac Roldan on 6/8/15.
//  Copyright © 2015 Redbooth. All rights reserved.
//

import Foundation
import Quick
import Nimble
import RealmSwift

@testable import RealmResultsController

class TableOfContentsSpec: QuickSpec {
    
    func openRealm() {
        
        let defaultRealmPath = Realm.defaultPath
        let bundleReamPath = NSBundle.mainBundle().resourcePath?.stringByAppendingPathComponent("test.realm")
        
        if !NSFileManager.defaultManager().fileExistsAtPath(defaultRealmPath) {
            try! NSFileManager.defaultManager().copyItemAtPath(bundleReamPath!, toPath: defaultRealmPath)
        }
    }
    
    
    override func spec() {
        
        openRealm()
        let realm = try! Realm()
        
        describe("the 'Documentation' directory") {
            it("has everything you need to get started") {
                let total = realm.objects(Task.self)
                expect(total.count).to(equal(1001))
            }
            
            context("if it doesn't have what you're looking for") {
                it("needs to be updated") {
//                    let you = You(awesome: true)
//                    expect{you.submittedAnIssue}.toEventually(beTruthy())
                }
            }
        }
    }
}