//
//  RealmResultsController.swift
//  redbooth-ios-sdk
//
//  Created by Isaac Roldan on 4/8/15.
//  Copyright © 2015 Redbooth Inc. All rights reserved.
//

import Foundation
import RealmSwift

enum RealmResultsChangeType: String {
    case Insert
    case Delete
    case Update
    case Move
}

protocol RealmResultsControllerDelegate {
    func willChangeResults(controller: AnyObject)
    func didChangeObject<U>(object: U, controller: AnyObject, atIndexPath: NSIndexPath, newIndexPath: NSIndexPath, changeType: RealmResultsChangeType)
    func didChangeSection<T>(section: Section<T>, controller: AnyObject, index: Int, changeType: RealmResultsChangeType)
    func didChangeResults(controller: AnyObject)
}

class RealmResultsController<T: Object, U> : RealmResultsCacheDelegate {
    var request: RealmRequest<T>
    var mapper: (T) -> U
    var delegate: RealmResultsControllerDelegate?
    var cache: RealmResultsCache<T>?
    
    var temporaryAdded: [T] = []
    var temporaryDeleted: [T] = []
    var temporaryUpdated: [T] = []

    init(request: RealmRequest<T>, mapper: (T)->(U)) {
        self.request = request
        self.mapper = mapper
        self.cache = RealmResultsCache<T>(objects: request.execute().toArray(T.self), request: request)
        self.cache?.delegate = self
        self.addNotificationObservers()
    }
    
    func performFetch() -> [U] {
        return request.execute().map(mapper)
    }
    
    
    //MARK: Cache delegate
    
    func didInsert<T: Object>(object: T, indexPath: NSIndexPath) {
        self.delegate?.didChangeObject(object, controller: self, atIndexPath: indexPath, newIndexPath: indexPath, changeType: .Insert)
    }
    
    func didUpdate<T: Object>(object: T, oldIndexPath: NSIndexPath, newIndexPath: NSIndexPath) {
        self.delegate?.didChangeObject(object, controller: self, atIndexPath: oldIndexPath, newIndexPath: newIndexPath, changeType: .Update)
    }
    
    func didDelete<T: Object>(object: T, indexPath: NSIndexPath) {
        self.delegate?.didChangeObject(object, controller: self, atIndexPath: indexPath, newIndexPath: indexPath, changeType: .Delete)
    }
    
    func didInsertSection<T : Object>(section: Section<T>, index: Int) {
        self.delegate?.didChangeSection(section, controller: self, index: index, changeType: .Insert)
    }
    
    func didDeleteSection<T : Object>(section: Section<T>, index: Int) {
        self.delegate?.didChangeSection(section, controller: self, index: index, changeType: .Delete)
    }
    
    
    //MARK: Realm Notifications
    
    func addNotificationObservers() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didReceiveRealmChanges:", name: "realmChanges", object: nil)
    }
    
    @objc func didReceiveRealmChanges(notification: NSNotification){
        guard case let dictionary as [String: [Object]] = notification.object else { return }
        temporaryAdded = dictionary["added"]?.filter({$0 is T && request.predicate.evaluateWithObject($0)}) as! [T]
        temporaryDeleted = dictionary["deleted"]?.filter({$0 is T && request.predicate.evaluateWithObject($0)}) as! [T]
        temporaryUpdated = dictionary["updated"]?.filter({$0 is T && request.predicate.evaluateWithObject($0)}) as! [T]
        temporaryUpdated = dictionary["updated"]?.filter({$0 is T && request.predicate.evaluateWithObject($0)}) as! [T]
        temporaryDeleted.extend(dictionary["updated"]?.filter({$0 is T && !request.predicate.evaluateWithObject($0)}) as! [T])
        finishWriteTransaction()
    }

    func pendingChanges() -> Bool{
        return temporaryAdded.count > 0 ||
            temporaryDeleted.count > 0 ||
            temporaryUpdated.count > 0
    }
    
    func finishWriteTransaction() {
        if !pendingChanges() { return }
        self.delegate?.willChangeResults(self)
        cache?.insert(temporaryAdded)
        cache?.delete(temporaryDeleted)
        cache?.update(temporaryUpdated)
        temporaryAdded.removeAll()
        temporaryDeleted.removeAll()
        temporaryUpdated.removeAll()
        self.delegate?.didChangeResults(self)
    }
}
