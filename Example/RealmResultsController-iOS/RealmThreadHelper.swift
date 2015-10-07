//
//  RealmThreadHelper.swift
//  RealmResultsController
//
//  Created by Isaac Roldan on 7/10/15.
//  Copyright © 2015 Redbooth. All rights reserved.
//

import Foundation


/**
Execute a block in the main thread. 
If we are already in it, just execute. If not, do a dispatch to execute it.

You can select if the execution should be sync or async (careful with deadlocks!!)

- parameter sync:  Bool, true if the execution should be dispatch_sync, false for dispatch_async
- parameter block: Block to execute
*/
func executeOnMainThread(sync: Bool = false, block: ()->()) {
    if NSThread.currentThread().isMainThread {
        block()
    }
    else if sync {
        dispatch_sync(dispatch_get_main_queue(), block)
    }
    else {
        dispatch_async(dispatch_get_main_queue(), block)
    }
}
