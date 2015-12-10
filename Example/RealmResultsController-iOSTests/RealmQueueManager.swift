//
//  RealmQueueManager.swift
//  RealmResultsController
//
//  Created by Pol Quintana on 10/12/15.
//  Copyright © 2015 Redbooth. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import RealmResultsController

private let blocksTimeout: UInt32 = 1

class RealmQueueManagerSpec: QuickSpec {
    private var queueManager = RealmQueueManager()
    private var thread1BlockHasBeenFired = false
    private var thread2BlockHasBeenFired = false
    private var timeoutHasBeenReached = false
    
    func fireThread1Block() {
        let queue = dispatch_queue_create("THREAD 1", DISPATCH_QUEUE_SERIAL)
        Threading.executeOnQueue(queue, sync: true) {
            self.queueManager.addOperation {
                self.thread1BlockHasBeenFired = true
                sleep(2)
            }
        }
    }
    
    func fireThread2Block() {
        let queue = dispatch_queue_create("THREAD 2", DISPATCH_QUEUE_SERIAL)
        Threading.executeOnQueue(queue, sync: true) {
            self.queueManager.addOperation {
                self.thread2BlockHasBeenFired = true
                sleep(2)
            }
        }
    }
    
    func oneBlockFired() -> Bool {
        let a = self.thread1BlockHasBeenFired || self.thread2BlockHasBeenFired
        return a && !(self.thread1BlockHasBeenFired && self.thread2BlockHasBeenFired)
    }
    
    override func spec() {
        context("addOperation(withBlock:)") {
            context("enqueued operations") {
                let queueManager = RealmQueueManager(serial: false)
                var block1Executed = false
                var block2Executed = false
                let block1 = {
                    block1Executed = true
                    sleep(blocksTimeout)
                }
                let block2 = {
                    block2Executed = true
                    sleep(blocksTimeout)
                }
                beforeEach {
                    queueManager.addOperation(withBlock: block1)
                    queueManager.addOperation(withBlock: block2)
                }
                afterEach {
                    block1Executed = false
                    block2Executed = false
                }
                it("should have executed the block 1") {
                    expect(block1Executed).toEventually(beTruthy())
                }
                it("should have enqueued the execution of the block 2") {
                    expect(block2Executed).toEventually(beFalsy())
                }
                it("should have executed the block 2 when reaching the 5 seconds timeout") {
                    expect(block2Executed).toEventually(beTruthy(), timeout: 5)
                }
            }
            context("serial operations") {
                let queueManager = RealmQueueManager(serial: true)
                var block1Executed = false
                var block2Executed = false
                let block1 = {
                    block1Executed = true
                    sleep(blocksTimeout)
                }
                let block2 = {
                    block2Executed = true
                    sleep(blocksTimeout)
                }
                beforeEach {
                    queueManager.addOperation(withBlock: block1)
                    queueManager.addOperation(withBlock: block2)
                }
                afterEach {
                    block1Executed = false
                    block2Executed = false
                }
                it("should have instantly executed the block 1") {
                    expect(block1Executed).to(beTruthy())
                }
                it("should have NOT enqueued the execution of the block 2") {
                    expect(block2Executed).to(beTruthy())
                }
            }
            
            context("equeued operations from different threads") {
                beforeEach {
                    let date = NSDate().dateByAddingTimeInterval(1)
                    let timer1 = NSTimer(fireDate: date, interval: 0, target: self, selector: "fireThread1Block", userInfo: nil, repeats: false)
                    let timer2 = NSTimer(fireDate: date, interval: 0, target: self, selector: "fireThread2Block", userInfo: nil, repeats: false)
                    NSRunLoop.currentRunLoop().addTimer(timer1, forMode: NSDefaultRunLoopMode)
                    NSRunLoop.currentRunLoop().addTimer(timer2, forMode: NSDefaultRunLoopMode)
                }
                it("should have executed only one block") {
                    expect(self.oneBlockFired()).toEventually(beTruthy(), timeout: 2)
                }
            }
        }
    }
}