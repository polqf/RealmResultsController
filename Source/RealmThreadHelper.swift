//
//  RealmThreadHelper.swift
//  RealmResultsController
//
//  Created by Isaac Roldan on 7/10/15.
//  Copyright © 2015 Redbooth. All rights reserved.
//

import Foundation


struct Threading {
    static let isTesting: Bool = {
        let environment = ProcessInfo.processInfo.environment
        return environment["TEST"] != nil
    }()
    
    /**
     Execute a block in the main thread.
     If we are already in it, just execute. If not, do a dispatch to execute it.
     
     You can select if the execution should be sync or async (careful with deadlocks!!)
     
     - parameter sync:  Bool, true if the execution should be dispatch_sync, false for dispatch_async
     - parameter block: Block to execute
     */
    static func executeOnMainThread(_ sync: Bool = false, block: @escaping ()->()) {
        guard !Thread.current.isMainThread else {
            block()
            return
        }
        executeOnQueue(DispatchQueue.main, sync: sync, block: block)
    }
    
    /**
     Execute a block in the passed queue.
     
     You can select if the execution should be sync or async (careful with deadlocks!!)
     
     - parameter sync:  Bool, true if the execution should be dispatch_sync, false for dispatch_async
     - parameter block: Block to execute
     */
    static func executeOnQueue(_ queue: DispatchQueue, sync: Bool = false, block: @escaping ()->()) {
        guard !isTesting else { return queue.sync(execute: block) }
        sync ? queue.sync(execute: block) : queue.async(execute: block)
    }
}
