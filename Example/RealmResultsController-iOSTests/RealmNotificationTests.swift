//
//  RealmNotificationTests.swift
//  RealmResultsController
//
//  Created by Pol Quintana on 6/8/15.
//  Copyright © 2015 Redbooth.
//

import Foundation
import Quick
import Nimble
import RealmSwift

@testable import RealmResultsController

class RealmNotificationSpec: QuickSpec {
    override func spec() {
        var realm: Realm!
        beforeSuite {
            RealmTestHelper.loadRealm()
            realm = try! Realm()
        }
        describe("loggerForRealm(realm:)") {
            var createdLogger: RealmLogger!
            context("Create a logger") {
                beforeEach {
                    createdLogger = RealmNotification.logger(for: realm)
                }
                it("Should have stored the logger in its shared instance") {
                    expect(RealmNotification.sharedInstance.loggers.count).to(equal(1))
                    expect(RealmNotification.sharedInstance.loggers.first!) === createdLogger
                }
            }
            context("Retrieve a created logger") {
                var retrievedLogger: RealmLogger!
                beforeEach {
                    retrievedLogger = RealmNotification.logger(for: realm)
                }
                it("Should have retrieve the logger stored in its shared instance") {
                    expect(RealmNotification.sharedInstance.loggers.count).to(equal(1))
                    expect(retrievedLogger) === createdLogger
                }
            }
        }
    }
}
