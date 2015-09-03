//
//  RealmResultsController.swift
//  redbooth-ios-sdk
//
//  Created by Isaac Roldan on 4/8/15.
//  Copyright © 2015 Redbooth Inc.
//

import Foundation
import UIKit
import RealmSwift

enum RRCError: ErrorType {
    case InvalidKeyPath
    case EmptySortDescriptors
}

public enum RealmResultsChangeType: String {
    case Insert
    case Delete
    case Update
    case Move
}

public protocol RealmResultsControllerDelegate: class {
    func willChangeResults(controller: AnyObject)
    func didChangeObject<U>(object: U, controller: AnyObject, oldIndexPath: NSIndexPath, newIndexPath: NSIndexPath, changeType: RealmResultsChangeType)
    func didChangeSection<U>(section: RealmSection<U>, controller: AnyObject, index: Int, changeType: RealmResultsChangeType)
    func didChangeResults(controller: AnyObject)
}

public class RealmResultsController<T: Object, U> : RealmResultsCacheDelegate {
    public weak var delegate: RealmResultsControllerDelegate?
    var _test: Bool = false
    var populating: Bool = false
    var observerAdded: Bool = false
    var cache: RealmResultsCache<T>!
    private(set) public var request: RealmRequest<T>
    private(set) public var filter: (T -> Bool)?
    var mapper: T -> U
    var sectionKeyPath: String? = ""
    var backgroundQueue = dispatch_queue_create("com.RRC.\(arc4random_uniform(1000))", DISPATCH_QUEUE_SERIAL)
    
    var temporaryAdded: [T] = []
    var temporaryUpdated: [T] = []
    var temporaryDeleted: [T] = []

    /**
    All results separated by the sectionKeyPath in RealmSection<U>
    
    Warning: This is computed variable that maps all the avaliable sections using the mapper. Could be an expensive operation
    Warning2: The RealmSections contained in the array do not contain objects, only its keyPath
    */
    public var sections: [RealmSection<U>] {
        return cache.sections.map(realmSectionMapper)
    }
    
    /// Number of sections in the RealmResultsController
    public var numberOfSections: Int {
        return cache.sections.count
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        observerAdded = false
    }
    
    
    //MARK: Initializers

    /**
    Create a RealmResultsController with a Request, a SectionKeypath to group the results and a mapper.
    This init NEEDS a mapper, and all the Realm Models (T) will be transformed using the mapper
    to objects of type (U). Done this way to avoid using Realm objects that are not thread safe.
    And to decouple the Model layer of the View Layer.
    If you want the RRC to return Realm objects that are thread safe, you should use the init
    that doesn't require a mapper.
    
    NOTE: If sectionKeyPath is used, it must be equal to the property used in the first SortDescriptor
    of the RealmRequest. If not, RRC will throw an error.
    NOTE2: Realm does not support sorting by KeyPaths, so you must only use properties of the model
    you want to fetch and not KeyPath to any relationship
    NOTE3: The RealmRequest needs at least one SortDescriptor
    
    - param: request        Request to fetch objects
    - param: sectionKeyPath KeyPath to group the results by sections
    - param: mapper         Mapper to map the results.
    
    - returns: Self
    */
    public init(request: RealmRequest<T>, sectionKeyPath: String? ,mapper: T -> U, filter: (T -> Bool)? = nil) throws {
        self.request = request
        self.mapper = mapper
        self.sectionKeyPath = sectionKeyPath
        self.cache = RealmResultsCache<T>(request: request, sectionKeyPath: sectionKeyPath)
        self.filter = filter
        if sortDescriptorsAreEmpty(request.sortDescriptors) {
            throw RRCError.EmptySortDescriptors
        }
        if !keyPathIsValid(sectionKeyPath, sorts: request.sortDescriptors) {
            throw RRCError.InvalidKeyPath
        }
        self.cache?.delegate = self
    }
    
    /**
    This INIT does not require a mapper, instead will use an empty mapper.
    If you plan to use this INIT, you should create the RRC specifiyng T = U
    Ex: let RRC = RealmResultsController<TaskModel, TaskModel>....
    
    All objects sent to the delegate of the RRC will be of the model type but
    they will be "mirrors", i.e. they don't belong to any Realm DB.
    
    NOTE: If sectionKeyPath is used, it must be equal to the property used in the first SortDescriptor
    of the RealmRequest. If not, RRC will throw an error
    NOTE2: The RealmRequest needs at least one SortDescriptor
    
    - param: request        Request to fetch objects
    - param: sectionKeyPath keyPath to group the results of the request
    
    - returns: self
    */
    public convenience init(request: RealmRequest<T>, sectionKeyPath: String?) throws {
        try self.init(request: request, sectionKeyPath: sectionKeyPath, mapper: {$0 as! U})
    }
    
    internal convenience init(forTESTRequest request: RealmRequest<T>, sectionKeyPath: String?, mapper: (T)->(U)) throws {
        try self.init(request: request, sectionKeyPath: sectionKeyPath, mapper: mapper)
        self._test = true
    }
    
    /**
    Update the filter currently used in the RRC by a new one.
    
    This func resets completetly the RRC, so:
    - It will force the RRC to clean all its cache and refetch all the objects.
    - You MUST do a reloadData() in your UITableView after calling this method.
    - Not refreshing the table could cause a crash because the indexes changed.
    
    :param: newFilter A Filter closure applied to T: Object
    */
    public func updateFilter(newFilter: T -> Bool) {
        filter = newFilter
        performFetch()
    }
    
    
    //MARK: Fetch
    
    /**
    Fetches the initial data for the RealmResultsController
    
    Atention: Must be called after the initialization and should be called only once
    */
    public func performFetch() {
        populating = true
        var objects = self.request.execute().toArray().map(getMirror)
        if let filter = filter {
            objects = objects.filter(filter)
        }
        self.cache.reset(objects)
        populating = false
        if !observerAdded { self.addNotificationObservers() }
    }

    
    //MARK: Helpers
    
    /**
    Returns the number of objects at a given section index
    
    - param: sectionIndex Int
    
    - returns: the objects count at the sectionIndex
    */
    public func numberOfObjectsAt(sectionIndex: Int) -> Int {
        return cache.sections[sectionIndex].objects.count
    }

    /**
    Returns the mapped object at a given NSIndexPath
    
    - param: indexPath IndexPath for the desired object
    
    - returns: the object as U (mapped)
    */
    public func objectAt(indexPath: NSIndexPath) -> U {
        let object = cache.sections[indexPath.section].objects[indexPath.row] as! T
        return self.mapper(object)
    }

    private func sortDescriptorsAreEmpty(sorts: [SortDescriptor]) -> Bool {
        return sorts.first == nil
    }
    
    // At this point, we are sure sorts.first always has a SortDescriptor
    private func keyPathIsValid(keyPath: String?, sorts: [SortDescriptor]) -> Bool {
        if keyPath == nil { return true }
        return keyPath == sorts.first!.property
    }
    
    private func realmSectionMapper<S>(section: Section<S>) -> RealmSection<U> {
        return RealmSection<U>(objects: nil, keyPath: section.keyPath)
    }
    
    
    //MARK: Cache delegate
    
    func didInsert<T: Object>(object: T, indexPath: NSIndexPath) {
        executeOnMainThread {
            self.delegate?.didChangeObject(object, controller: self, oldIndexPath: indexPath, newIndexPath: indexPath, changeType: .Insert)
        }
    }
    
    func didUpdate<T: Object>(object: T, oldIndexPath: NSIndexPath, newIndexPath: NSIndexPath, changeType: RealmResultsChangeType) {
        executeOnMainThread {
            self.delegate?.didChangeObject(object, controller: self, oldIndexPath: oldIndexPath, newIndexPath: newIndexPath, changeType: changeType)
        }
    }
    
    func didDelete<T: Object>(object: T, indexPath: NSIndexPath) {
        executeOnMainThread {
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
        observerAdded = true
    }
    
    @objc func didReceiveRealmChanges(notification: NSNotification) {
        guard case let notificationObject as [String : [RealmChange]] = notification.object else { return }
        guard notificationObject.keys.first == request.realm.path else { return }
        executeOnCorrectThread {
            let objects = notificationObject[self.request.realm.path]!
            self.refetchObjects(objects)
            self.finishWriteTransaction()
        }
    }
    
    private func refetchObjects(objects: [RealmChange]) {
        for object in objects {
            if String(object.type) != String(T.self) { continue }
            if object.action == RealmAction.Delete {
                temporaryDeleted.append(object.mirror as! T)
                continue
            }
            
            var passesFilter = true
            let passesPredicate = self.request.predicate.evaluateWithObject(object.mirror as! T)
            
            if let filter = filter {
                executeOnMainThread(true) {
                    passesFilter = filter(object.mirror as! T)
                }
            }
    
            if object.action == RealmAction.Create && passesPredicate && passesFilter {
                temporaryAdded.append(object.mirror as! T)
            }
            else if object.action == RealmAction.Update {
                passesPredicate ? temporaryUpdated.append(object.mirror as! T) : temporaryDeleted.append(object.mirror as! T)
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
        var objectsToMove: [T] = []
        var objectsToUpdate: [T] = []
        for object in temporaryUpdated {
            cache.updateType(object) == .Move ? objectsToMove.append(object) : objectsToUpdate.append(object)
        }
        
        temporaryDeleted.appendContentsOf(objectsToMove)
        temporaryAdded.appendContentsOf(objectsToMove)
        cache.update(objectsToUpdate)
        cache.delete(temporaryDeleted)
        cache.insert(temporaryAdded)
        temporaryAdded.removeAll()
        temporaryDeleted.removeAll()
        temporaryUpdated.removeAll()
        executeOnMainThread {
            self.delegate?.didChangeResults(self)
        }
    }
    
    
    //MARK: Thread management
    
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
    func executeOnCorrectThread(block: ()->()) {
        _test ? dispatch_sync(backgroundQueue, block) : dispatch_async(backgroundQueue, block)
    }
    
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
}
