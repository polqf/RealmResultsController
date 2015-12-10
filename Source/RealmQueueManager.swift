//
//  RealmQueueManager.swift
//  RealmResultsController
//
//  Created by Pol Quintana on 09/12/15.
//  Copyright © 2015 Redbooth. All rights reserved.
//

import Foundation

struct RealmQueueManager {
    let operationQueue: NSOperationQueue = {
        let queue = NSOperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.name = "com.RRC.\(arc4random_uniform(1000))"
        return queue
    }()
    
    func addOperation(withBlock block: ()->()) {
        guard !Threading.isTesting else {
            block()
            return
        }
        operationQueue.addOperationWithBlock(block)
    }
}