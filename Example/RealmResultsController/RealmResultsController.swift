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
    func didChangeSection<U>(section: RealmSection<U>, controller: AnyObject, index: Int, changeType: RealmResultsChangeType)
    func didChangeResults(controller: AnyObject)
}

public class RealmResultsController<T: Object, U> : RealmResultsCacheDelegate {
    var delegate: RealmResultsControllerDelegate?
    var cache: RealmResultsCache<T>!
    var request: RealmRequest<T>
    var mapper: (T) -> U
    var sectionKeyPath: String? = ""
    public var sections: [RealmSection<U>] {
        return cache.sections.map(realmSectionMapper)
    }
    public var allObjects: [U] {
        return sections.flatMap {$0.objects}
    }
    
    var temporaryAdded: [T] = []
    var temporaryDeleted: [T] = []
    var temporaryUpdated: [T] = []

    public init(request: RealmRequest<T>, sectionKeyPath: String? ,mapper: (T)->(U)) {
        self.request = request
        self.mapper = mapper
        self.sectionKeyPath = sectionKeyPath
        self.cache = RealmResultsCache<T>(request: request, sectionKeyPath: sectionKeyPath)
        self.cache?.delegate = self
        self.addNotificationObservers()
    }
    
    public func performFetch() -> [RealmSection<U>] {
        let newObjects = request.execute().toArray(T.self)
        cache.reset(newObjects)
        return sections
    }
    
    func realmSectionMapper<S>(section: Section<S>) -> RealmSection<U> {
        let mapped = mapItems(section.allObjects)
        return RealmSection<U>(objects: mapped, keyPath: section.keyPath)
    }
    
    /**
    Hackish!
    if a class has a generic T, and a method has another generic T (or even with another name)
    and considering that the map function is defined to return a generic T. 
    If you want to map inside that method, you are going to have a bad time.
    This method is a wrapper of the map function to work with all the generic mess.
    
    :param: items Array of items to map, they should be of type T (defined by the class)
    if the items are not T, this will crash.
    
    :returns: Array of mapped items (they should be U, defined by the class)
    */
    private func mapItems<S: Object>(items: [S]) -> [U] {
        return items.map { mapper($0 as! T) }
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
        self.delegate?.didChangeSection(realmSectionMapper(section), controller: self, index: index, changeType: .Insert)
    }
    
    func didDeleteSection<T : Object>(section: Section<T>, index: Int) {
        self.delegate?.didChangeSection(realmSectionMapper(section), controller: self, index: index, changeType: .Delete)
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
        cache.insert(temporaryAdded)
        cache.delete(temporaryDeleted)
        cache.update(temporaryUpdated)
        temporaryAdded.removeAll()
        temporaryDeleted.removeAll()
        temporaryUpdated.removeAll()
        self.delegate?.didChangeResults(self)
    }
}
