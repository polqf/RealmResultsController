//
//  RealmResultsCache.swift
//  redbooth-ios-sdk
//
//  Created by Isaac Roldan on 4/8/15.
//  Copyright © 2015 Redbooth Inc.
//

import Foundation
import RealmSwift

enum RealmCacheUpdateType: String {
    case Move
    case Update
    case Insert
}

protocol RealmResultsCacheDelegate: class {
    func didInsertSection<T: RealmSwift.Object>(_ section: Section<T>, index: Int)
    func didDeleteSection<T: RealmSwift.Object>(_ section: Section<T>, index: Int)
    func didInsert<T: RealmSwift.Object>(_ object: T, indexPath: IndexPath)
    func didUpdate<T: RealmSwift.Object>(_ object: T, oldIndexPath: IndexPath, newIndexPath: IndexPath, changeType: RealmResultsChangeType)
    func didDelete<T: RealmSwift.Object>(_ object: T, indexPath: IndexPath)
}

/**
The Cache is responsible to store a copy of the current objects used by the RRC obtained by the original request.
It has an Array of sections where the objects are stored, always filtered and sorted by the request.

The array of sections is constructed depending on the SectionKeyPath given in the RRC creation.

When interacting with the cache is important to do it always in this order:
Taking into account that a MOVE is not an update but a pair of delete/insert operations.

- Deletions
- Insertions
- Updates (Only for objects that won't change position)

:important: always call the three methods, the operations are commited at the end
so calling only `delete` will change the cache but not call the delegate.
*/
class RealmResultsCache<T: Object> {
    var request: RealmRequest<T>
    var sectionKeyPath: String? = ""
    var sections: [Section<T>] = []
    let defaultKeyPathValue = "default"
    weak var delegate: RealmResultsCacheDelegate?
    
    var temporalDeletions: [T] = []
    var temporalDeletionsIndexPath: [T : IndexPath] = [:]
    
    
    //MARK: Initializer
    init(request: RealmRequest<T>, sectionKeyPath: String?) {
        self.request = request
        self.sectionKeyPath = sectionKeyPath
    }
    

    //MARK: Population
    func populateSections(with objects: [T]) {
        objects.forEach { getOrCreateSection(for: $0).insert($0) }
        sections.forEach { $0.sort() }
    }
  
    func reset(with objects: [T]) {
        sections.removeAll()
        populateSections(with: objects)
    }
    
    //MARK: Actions
    
    func insert(_ objects: [T]) {
        let mirrorsArray = sortedMirrors(objects)
        for object in mirrorsArray {
            let section = getOrCreateSection(for: object) //Calls the delegate when there is an insertion
            let rowIndex = section.insertSorted(object)
            guard let sectionIndex = index(for: section) else { continue }
            let indexPath = IndexPath(row: rowIndex, section: sectionIndex)
            
            // If the object was not deleted previously, it is just an INSERT.
            if !temporalDeletions.contains(object) {
                delegate?.didInsert(object, indexPath: indexPath)
                continue
            }
            
            // If the object was already deleted, then is a MOVE, and the insert/deleted
            // should be wrapped in only one operation to the delegate
            guard let oldIndexPath = temporalDeletionsIndexPath[object] else { continue }
            delegate?.didUpdate(object, oldIndexPath: oldIndexPath, newIndexPath: indexPath, changeType: RealmResultsChangeType.Move)
            guard let index = temporalDeletions.index(of: object) else { continue }
            temporalDeletions.remove(at: index)
            temporalDeletionsIndexPath.removeValue(forKey: object)
        }
        
        // The remaining objects, not MOVED or INSERTED, are DELETES, and must be deleted at the end
        for object in temporalDeletions {
            guard let oldIndexPath = temporalDeletionsIndexPath[object] else { continue }
            delegate?.didDelete(object, indexPath: oldIndexPath)
        }
        temporalDeletions.removeAll()
        temporalDeletionsIndexPath.removeAll()
    }
    
    func delete(_ objects: [T]) {
        var outdated: [T] = []
        for object in objects {
            guard let section = sectionForOutdateObject(object) else { continue }
            guard let index = section.indexForOutdatedObject(object),
                let object = section.objects.object(at: index) as? T else { continue }
            outdated.append(object)
        }
        
        let mirrorsArray = sortedMirrors(outdated).reversed() as [T]
        
        for object in mirrorsArray {
            guard let section = sectionForOutdateObject(object),
                let sectionIndex = index(for: section) else { continue }
            guard let index = section.deleteOutdatedObject(object) else { continue }
            let indexPath = IndexPath(row: index, section: sectionIndex)
            
            temporalDeletions.append(object)
            temporalDeletionsIndexPath[object] = indexPath
            
            if section.objects.count == 0 {
                sections.remove(at: (indexPath as NSIndexPath).section)
                delegate?.didDeleteSection(section, index: (indexPath as NSIndexPath).section)
            }
        }
    }
    
    
    func update(_ objects: [T]) {
        for object in objects {
            guard let oldSection = sectionForOutdateObject(object),
                let oldSectionIndex = index(for: oldSection),
                let oldIndexRow = oldSection.indexForOutdatedObject(object) else {
                insert([object])
                continue
            }
            
            let oldIndexPath = IndexPath(row: oldIndexRow, section: oldSectionIndex)
            
            _ = oldSection.deleteOutdatedObject(object)
            let newIndexRow = oldSection.insertSorted(object)
            let newIndexPath = IndexPath(row: newIndexRow, section: oldSectionIndex)
            delegate?.didUpdate(object, oldIndexPath: oldIndexPath, newIndexPath: newIndexPath, changeType: .Update)
        }
    }

    
    //MARK: Create
    
    private func createNewSection(named keyPath: String, notifyDelegate: Bool = true) -> Section<T> {
        let newSection = Section<T>(keyPath: keyPath, sortDescriptors: request.sortDescriptors.map(toNSSortDescriptor))
        sections.append(newSection)
        sortSections()
        let sectionIndex = index(for: newSection)!
        if notifyDelegate {
            delegate?.didInsertSection(newSection, index: sectionIndex)
        }
        return newSection
    }
    
    
    //MARK: Retrieve
    private func getOrCreateSection(for object: T) -> Section<T> {
        let key = keyPath(for: object)
        guard let objectSection = section(for: key) else {
            return createNewSection(named: key)
        }
        return objectSection
    }
    
    private func section(for keyPath: String, create: Bool = true) -> Section<T>? {
        let section = sections.filter{$0.keyPath == keyPath}
        return section.first
    }
    
    private func sectionForOutdateObject(_ object: T) -> Section<T>? {
        for section in sections {
            if let _ = section.indexForOutdatedObject(object) {
                return section
            }
        }
        let key = keyPath(for: object)
        return section(for: key)
    }
    
    
    //MARK: Indexes
    
    private func index(for section: Section<T>) -> Int? {
        return sections.index(of: section)
    }
    
    
    //MARK: Helpers
    
    /**
    Given an object this method returns the type of update that this object will 
    perform in the cache: .Move, .Update or .Insert
    
    :param: object Object to update
    
    :returns: Type of the update needed for the given object
    */
    func updateType(for object: T) -> RealmCacheUpdateType {
        //Sections
        guard let oldSection = sectionForOutdateObject(object) else { return .Insert }
        guard let newSection = section(for: keyPath(for: object)) else { return .Move }
        
        //OutdatedCopy
        guard let outdatedCopy = oldSection.outdatedObject(object) else { return .Insert }
        
        //Indexes
        guard let oldIndexRow = oldSection.delete(outdatedCopy) else { return .Insert }
        let newIndexRow = newSection.insertSorted(object)

        //Restore
        _ = newSection.delete(object)
        _ = oldSection.insertSorted(outdatedCopy)
        
        if oldSection == newSection && oldIndexRow == newIndexRow {
            return .Update
        }
        return .Move
    }
    
    func keyPath(for object: T) -> String {
        var keyPathValue = defaultKeyPathValue
        if let keyPath = sectionKeyPath {
            if keyPath.isEmpty { return defaultKeyPathValue }
            Threading.executeOnMainThread(true) {
                if let objectKeyPathValue = object.value(forKeyPath: keyPath) {
                    keyPathValue = String(describing: objectKeyPathValue)
                }
            }
        }
        return keyPathValue
    }
    
    /**
    Sort an array of objects (mirrors of the original realm objects)
    Using the SortDescriptors of the RealmRequest of the RRC.
    
    :param: mirrors Objects to sort
    
    :returns: sorted Array<T>
    */
    private func sortedMirrors(_ mirrors: [T]) -> [T] {
        let mutArray = NSMutableArray(array: mirrors)
        let sorts = request.sortDescriptors.map(toNSSortDescriptor)
        mutArray.sort(using: sorts)
        guard let sortedMirrors = NSArray(array: mutArray) as? [T] else {
            return []
        }
        return sortedMirrors
    }

    /**
    Sort the sections using the Given KeyPath
    */
    private func sortSections() {
        guard let sortd =  request.sortDescriptors.first else { return }
        let comparator: ComparisonResult = sortd.ascending ? .orderedAscending : .orderedDescending
        sections.sort { $0.keyPath.localizedCaseInsensitiveCompare($1.keyPath) == comparator }
    }
    
    /**
    Transforms a SortDescriptor into a NSSortDescriptor that can be applied to NSMutableArray
    
    :param: sort SortDescriptor object
    
    :returns: NSSortDescriptor
    */
    private func toNSSortDescriptor(_ sort: SortDescriptor) -> NSSortDescriptor {
        return NSSortDescriptor(key: sort.property, ascending: sort.ascending)
    }
}
