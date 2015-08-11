//
//  RealmResultsCache.swift
//  redbooth-ios-sdk
//
//  Created by Isaac Roldan on 4/8/15.
//  Copyright © 2015 Redbooth Inc. All rights reserved.
//

import Foundation
import RealmSwift


protocol RealmResultsCacheDelegate: class {
    func didInsertSection<T: Object>(section: Section<T>, index: Int)
    func didDeleteSection<T: Object>(section: Section<T>, index: Int)
    func didInsert<T: Object>(object: T, indexPath: NSIndexPath)
    func didUpdate<T: Object>(object: T, oldIndexPath: NSIndexPath, newIndexPath: NSIndexPath)
    func didDelete(indexPath: NSIndexPath)
}

class RealmResultsCache<T: Object> {
    var request: RealmRequest<T>
    var sectionKeyPath: String? = ""
    var sections: [Section<T>] = []
    let defaultKeyPathValue = "default"
    weak var delegate: RealmResultsCacheDelegate?
    
    init(request: RealmRequest<T>, sectionKeyPath: String?) {
        self.request = request
        self.sectionKeyPath = sectionKeyPath
    }
    
    func populateSections(objects: [T]) {
        for object in objects {
            let section = sectionForObject(object)
            section.insertSorted(object)
        }
    }
    
    func reset(objects: [T]) {
        sections.removeAll()
        populateSections(objects)
    }
    
    private func indexForSection(section: Section<T>) -> Int? {
        return sections.indexOf(section)
    }
    
    private func sectionForKeyPath(keyPath: String) -> Section<T> {
        let section = sections.filter{$0.keyPath == keyPath}
        if let s = section.first {
            return s
        }
        return createNewSection(keyPath)
    }
    
    private func sortSections() {
        sections.sortInPlace { $0.keyPath.localizedCaseInsensitiveCompare($1.keyPath) == NSComparisonResult.OrderedAscending }
    }
    
    private func toNSSortDescriptor(sort: SortDescriptor) -> NSSortDescriptor {
        return NSSortDescriptor(key: sort.property, ascending: sort.ascending)
    }
    
    private func createNewSection(keyPath: String) -> Section<T> {
        let newSection = Section<T>(keyPath: keyPath, sortDescriptors: request.sortDescriptors.map(toNSSortDescriptor))
        sections.append(newSection)
        sortSections()
        let index = indexForSection(newSection)!
        delegate?.didInsertSection(newSection, index: index)
        return newSection
    }
    
    private func sectionForObject(object: T) -> Section<T> {
        var keyPathValue = defaultKeyPathValue
        if let keyPath = sectionKeyPath {
            keyPathValue = String(object.valueForKeyPath(keyPath))
        }
        return sectionForKeyPath(keyPathValue)
    }
    
    private func sectionForRealmChange(object: RealmChange) -> Section<T>? {
        for section in sections {
            if let _ = section.objectForPrimaryKey(object.primaryKey) {
                return section
            }
        }
        return nil
    }
    
    private func sectionForOutdateObject(object: T) -> Section<T> {
        let primaryKey = T.primaryKey()!
        let primaryKeyValue = (object as Object).valueForKey(primaryKey)!
        for section in sections {
            for sectionObject in section.objects {
                let value = sectionObject.valueForKey(primaryKey)!
                if value.isEqual(primaryKeyValue) {
                    return section
                }
            }
        }
        return sectionForObject(object)
    }
    
    func insert(objects: [T]) {
        for object in objects {
            let section = sectionForObject(object)
            let index = section.insertSorted(object)
            let indexPath = NSIndexPath(forRow: index, inSection: indexForSection(section)!)
            delegate?.didInsert(object, indexPath: indexPath)
        }
    }
    
    func delete(objects: [RealmChange]) {
        for object in objects {
            guard let section = sectionForRealmChange(object) else { return }
            let index = section.delete(object)
            guard index >= 0 else { return }
            let indexPath = NSIndexPath(forRow: index, inSection: indexForSection(section)!)
            delegate?.didDelete(indexPath)
        }
    }
    
    func update(objects: [T]) {
        for object in objects {
            let oldSection = sectionForOutdateObject(object)
            let oldIndexRow = oldSection.deleteOutdatedObject(object)
            
            if oldIndexRow == -1 {
                insert([object])
                return
            }
            
            let newSection = sectionForObject(object)
            let newIndexRow = newSection.insertSorted(object)
            
            let newIndexPath = NSIndexPath(forRow: newIndexRow, inSection: indexForSection(newSection)!)
            let oldIndexPath = NSIndexPath(forRow: oldIndexRow, inSection: indexForSection(oldSection)!)
            
            delegate?.didUpdate(object, oldIndexPath: oldIndexPath, newIndexPath: newIndexPath)
        }
    }
}