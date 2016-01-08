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
    
    /**
    Notifies the receiver that the realm results controller is about to start processing of one or more changes due to an add, remove, move, or update.
    
    :param: controller The realm results controller that sent the message.
    */
    func willChangeResults(controller: AnyObject)
    
    /**
    Notifies the receiver that a fetched object has been changed due to an add, remove, move, or update.
    
    :param: controller   The realm results controller that sent the message.
    :param: object       The object in controller’s fetched results that changed.
    :param: oldIndexPath The index path of the changed object (this value is the same as newIndexPath for insertions).
    :param: newIndexPath The destination path for the object for insertions or moves (this value is the same as oldIndexPath for a deletion).
    :param: changeType   The type of change. For valid values see RealmResultsChangeType.
    */
    func didChangeObject<U>(controller: AnyObject, object: U, oldIndexPath: NSIndexPath, newIndexPath: NSIndexPath, changeType: RealmResultsChangeType)
    
    /**
    Notifies the receiver of the addition or removal of a section.
    
    :param: controller The realm results controller that sent the message.
    :param: section    The section that changed.
    :param: index      The index of the changed section.
    :param: changeType The type of change (insert or delete).
    */
    func didChangeSection<U>(controller: AnyObject, section: RealmSection<U>, index: Int, changeType: RealmResultsChangeType)
    
    /**
    Notifies the receiver that the realm results controller has completed processing of one or more changes due to an add, remove, move, or update.
    
    :param: controller The realm results controller that sent the message.
    */
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
    var queueManager: RealmQueueManager = RealmQueueManager()
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
        var objects = self.request.execute().toArray().map{ $0.getMirror() }
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
        if cache.sections.count == 0 { return 0 }
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
        Threading.executeOnMainThread {
            self.delegate?.didChangeObject(self, object: object, oldIndexPath: indexPath, newIndexPath: indexPath, changeType: .Insert)
        }
    }
    
    func didUpdate<T: Object>(object: T, oldIndexPath: NSIndexPath, newIndexPath: NSIndexPath, changeType: RealmResultsChangeType) {
        Threading.executeOnMainThread {
            self.delegate?.didChangeObject(self, object: object, oldIndexPath: oldIndexPath, newIndexPath: newIndexPath, changeType: changeType)
        }
    }
    
    func didDelete<T: Object>(object: T, indexPath: NSIndexPath) {
        Threading.executeOnMainThread {
            self.delegate?.didChangeObject(self, object: object, oldIndexPath: indexPath, newIndexPath: indexPath, changeType: .Delete)
        }
    }
    
    func didInsertSection<T : Object>(section: Section<T>, index: Int) {
        if populating { return }
        Threading.executeOnMainThread {
            self.delegate?.didChangeSection(self, section: self.realmSectionMapper(section), index: index, changeType: .Insert)
        }
    }
    
    func didDeleteSection<T : Object>(section: Section<T>, index: Int) {
        Threading.executeOnMainThread {
            self.delegate?.didChangeSection(self, section: self.realmSectionMapper(section), index: index, changeType: .Delete)
        }
    }
    
    
    //MARK: Realm Notifications
    
    private func addNotificationObservers() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didReceiveRealmChanges:", name: "realmChanges", object: nil)
        observerAdded = true
    }
    
    @objc func didReceiveRealmChanges(notification: NSNotification) {
        guard case let notificationObject as [String : [RealmChange]] = notification.object
            where notificationObject.keys.first == request.realm.path,
            let objects = notificationObject[self.request.realm.path] else { return }
        queueManager.addOperation {
            self.refetchObjects(objects)
            self.finishWriteTransaction()
        }
        
    }
    
    private func refetchObjects(objects: [RealmChange]) {
        for object in objects {
            guard String(object.type) == String(T.self), let mirrorObject = object.mirror as? T else { continue }
            if object.action == RealmAction.Delete {
                temporaryDeleted.append(mirrorObject)
                continue
            }
            
            var passesFilter = true
            var passesPredicate = true
            
            Threading.executeOnMainThread(true) {
                passesPredicate = self.request.predicate.evaluateWithObject(mirrorObject)
                if let filter = self.filter {
                    passesFilter = filter(mirrorObject)
                }
            }
    
            if object.action == RealmAction.Create && passesPredicate && passesFilter {
                temporaryAdded.append(mirrorObject)
            }
            else if object.action == RealmAction.Update {
                if passesFilter && passesPredicate {
                    temporaryUpdated.append(mirrorObject)
                }
                else {
                    temporaryDeleted.append(mirrorObject)
                }
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
        Threading.executeOnMainThread(true) {
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
        Threading.executeOnMainThread(true) {
            self.delegate?.didChangeResults(self)
        }
    }
}
