//
//  RealmQueueManager.swift
//  RealmResultsController
//
//  Created by Pol Quintana on 09/12/15.
//  Copyright © 2015 Redbooth. All rights reserved.
//

import Foundation

struct RealmQueueManager {
    private var sync: Bool = false
    let operationQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.name = "com.RRC.\(arc4random_uniform(1000))"
        return queue
    }()
    
    init(sync: Bool = false) {
        self.sync = sync
    }
    
    func addOperation(withBlock block: @escaping ()->()) {
        guard !sync else {
            block()
            return
        }
        operationQueue.addOperation(block)
    }
}
