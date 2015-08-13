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

protocol RealmResultsControllerDelegate: class {
    func willChangeResults(controller: AnyObject)
    func didChangeObject<U>(object: U, controller: AnyObject, oldIndexPath: NSIndexPath, newIndexPath: NSIndexPath, changeType: RealmResultsChangeType)
    func didChangeSection<U>(section: RealmSection<U>, controller: AnyObject, index: Int, changeType: RealmResultsChangeType)
    func didChangeResults(controller: AnyObject)
}

public class RealmResultsController<T: Object, U> : RealmResultsCacheDelegate {
    weak var delegate: RealmResultsControllerDelegate?
    var _test: Bool = false
    var populating: Bool = false
    var cache: RealmResultsCache<T>!
    var request: RealmRequest<T>
    var mapper: (T) -> U
    var sectionKeyPath: String? = ""
    var backgroundQueue = dispatch_queue_create("com.RRC.\(arc4random_uniform(1000))", DISPATCH_QUEUE_SERIAL)
    var sections: [RealmSection<U>] {
        return cache.sections.map(realmSectionMapper)
    }
    public var numberOfSections: Int {
        return cache.sections.count
    }
    
    var temporaryAdded: [T] = []
    var temporaryUpdated: [T] = []
    var temporaryDeleted: [RealmChange] = []

    /**
    Create a RealmResultsController with a Request, a SectionKeypath to group the results and a mapper.
    This init NEEDS a mapper, and all the Realm Models (T) will be transformed using the mapper
    to objects of type (U). Done this way to avoid using Realm objects that are not thread safe.
    And to decouple the Model layer of the View Layer.
    If you want the RRC to return Realm objects that are thread safe, you should use the init
    that doesn't require a mapper.
    
    :param: request        Request to fetch objects
    :param: sectionKeyPath KeyPath to group the results by sections
    :param: mapper         Mapper to map the results.
    
    :returns: Self
    */
    public init(request: RealmRequest<T>, sectionKeyPath: String? ,mapper: (T)->(U)) {
        self.request = request
        self.mapper = mapper
        self.sectionKeyPath = sectionKeyPath
        self.cache = RealmResultsCache<T>(request: request, sectionKeyPath: sectionKeyPath)
        self.cache?.delegate = self
        self.addNotificationObservers()
    }
    
    /**
    This INIT does not require a mapper, instead will use an empty mapper.
    If you plan to use this INIT, you should create the RRC specifiyng T = U
    Ex: let RRC = RealmResultsController<TaskModel, TaskModel>....
    
    All objects sent to the delegate of the RRC will be of the model type but
    they will be "mirrors", i.e. they don't belong to any Realm DB.
    
    :param: request        Request to fetch objects
    :param: sectionKeyPath keyPath to group the results of the request
    
    :returns: self
    */
    public convenience init(request: RealmRequest<T>, sectionKeyPath: String?) {
        self.init(request: request, sectionKeyPath: sectionKeyPath) { (object: T) -> (U) in
            return object as! U
        }
    }
    
    convenience init(forTESTRequest request: RealmRequest<T>, sectionKeyPath: String?, mapper: (T)->(U)) {
        self.init(request: request, sectionKeyPath: sectionKeyPath, mapper: mapper)
        self._test = true
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    public func numberOfObjectsAt(sectionIndex: Int) -> Int {
        
        return cache.sections[sectionIndex].objects.count
    }
    
    public func objectAt(indexPath: NSIndexPath) -> U {
        // TODO: make sure the indexPath exists
        let object = cache.sections[indexPath.section].allObjects[indexPath.row]
        return self.mapper(object)
    }
    
    public func performFetch() -> [RealmSection<U>] {
        populating = true
        request.execute().toArray(T.self)
        let objects = self.request.execute().toArray(T.self).map(getMirror)
        self.cache.reset(objects)
        populating = false
        return sections
    }
    
    func realmSectionMapper<S>(section: Section<S>) -> RealmSection<U> {
        return RealmSection<U>(objects: nil, keyPath: section.keyPath)
    }
    
    /**
    Hackish!
    if a class has a generic T, and a method has another generic T (or even with another name)
    and considering that the map function is defined to return a generic T. 
    If you want to map inside that method, you are going to have a bad time.
    This method is a wrapper of the map function to work with all the generic mess.
    
    NOTE: not used for the moment, leave it here in case we need it.
    
    :param: items Array of items to map, they should be of type T (defined by the class)
    if the items are not T, this will crash.
    
    :returns: Array of mapped items (they should be U, defined by the class)
    */
//    private func mapItems<S: Object>(items: [S]) -> [U] {
//        return items.map { mapper($0 as! T) }
//    }
    
    
    func executeOnCorrectThread(block: ()->()) {
        _test ? dispatch_sync(backgroundQueue, block) : dispatch_async(backgroundQueue, block)
    }
    
    func executeOnMainThread(block: ()->()) {
        if NSThread.currentThread().isMainThread {
            block()
        }
        else {
            dispatch_async(dispatch_get_main_queue(), block)
        }
    }
    
    //MARK: Cache delegate
    
    func didInsert<T: Object>(object: T, indexPath: NSIndexPath) {
        executeOnMainThread {
            self.delegate?.didChangeObject(object, controller: self, oldIndexPath: indexPath, newIndexPath: indexPath, changeType: .Insert)
        }

    }
    
    func didUpdate<T: Object>(object: T, oldIndexPath: NSIndexPath, newIndexPath: NSIndexPath) {
        executeOnMainThread {
            var changeType: RealmResultsChangeType = .Update
            if oldIndexPath != newIndexPath {
                changeType = .Move
            }
            self.delegate?.didChangeObject(object, controller: self, oldIndexPath: oldIndexPath, newIndexPath: newIndexPath, changeType: changeType)
        }
    }
    
    func didDelete(indexPath: NSIndexPath) {
        executeOnMainThread {
            let object = U.self
            self.delegate?.didChangeObject(object, controller: self, oldIndexPath: indexPath, newIndexPath: indexPath, changeType: .Delete)
        }
    }
    
    func didInsertSection<T : Object>(section: Section<T>, index: Int) {
        if populating { return }
        executeOnMainThread {
            self.delegate?.didChangeSection(realmSectionMapper(section), controller: self, index: index, changeType: .Insert)
        }
    }
    
    func didDeleteSection<T : Object>(section: Section<T>, index: Int) {
        executeOnMainThread {
            self.delegate?.didChangeSection(realmSectionMapper(section), controller: self, index: index, changeType: .Delete)
        }
    }
    
    
    //MARK: Realm Notifications
    
    private func addNotificationObservers() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didReceiveRealmChanges:", name: "realmChanges", object: nil)
    }
    
    @objc func didReceiveRealmChanges(notification: NSNotification) {
        let block: () -> () = {
                guard case let objects as [RealmChange] = notification.object else { return }
                self.refetchObjects(objects)
                self.finishWriteTransaction()
        }
        executeOnCorrectThread(block)
    }
    
    private func refetchObjects(objects: [RealmChange]) {
        for object in objects {
            if String(object.type) != String(T.self) { continue }
            if object.action == RealmAction.Delete {
                temporaryDeleted.append(object)
                continue
            }
            
            let passesPredicate = self.request.predicate.evaluateWithObject(object.mirror as! T)

            if object.action == RealmAction.Create && passesPredicate {
                temporaryAdded.append(object.mirror as! T)
            }
            if object.action == RealmAction.Update {
                passesPredicate ? temporaryUpdated.append(object.mirror as! T) : temporaryDeleted.append(object)
            }
        }
    }

    func pendingChanges() -> Bool{
        return temporaryAdded.count > 0 ||
            temporaryDeleted.count > 0 ||
            temporaryUpdated.count > 0
    }
    
    private func finishWriteTransaction() {
        if !pendingChanges() { return }
        executeOnMainThread {
            self.delegate?.willChangeResults(self)
        }
        cache.insert(temporaryAdded)
        cache.delete(temporaryDeleted)
        cache.update(temporaryUpdated)
        temporaryAdded.removeAll()
        temporaryDeleted.removeAll()
        temporaryUpdated.removeAll()
        executeOnMainThread {
            self.delegate?.didChangeResults(self)
        }
    }
    
}
