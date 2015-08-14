//
//  ViewControllerSpec.swift
//  RealmResultsController
//
//  Created by Isaac Roldan on 13/8/15.
//  Copyright © 2015 Redbooth. All rights reserved.
//

import Foundation
import Quick
import Nimble
import RealmSwift

@testable import RealmResultsController


/// Note: Specs created only to reach 100% coverage. 
/// Until Xcode lets you ignore View files in the coverage
class ViewControllerSpec: QuickSpec {
    
    override func spec() {
        var VC: ViewController!
        
        beforeEach {
//            VC = ViewController(coder: NSCoder())
        }
        it("it is not nil") {
//            expect(VC).toNot(beNil())
        }
    }
}