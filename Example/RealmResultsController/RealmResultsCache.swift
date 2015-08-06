//
//  RealmResultsCache.swift
//  redbooth-ios-sdk
//
//  Created by Isaac Roldan on 4/8/15.
//  Copyright © 2015 Redbooth Inc. All rights reserved.
//

import Foundation
import RealmSwift


extension SortDescriptor {
    func toNSSortDescriptor() -> NSSortDescriptor {
        return NSSortDescriptor(key: self.property, ascending: self.ascending)
    }
}

protocol RealmResultsCacheDelegate {
    func didDeleteSection(index: Int)
    func didInsertSection(index: Int)
    func didInsert<T: Object>(object: T, indexPath: NSIndexPath)
    func didDelete<T: Object>(object: T, indexPath: NSIndexPath)
    func didUpdate<T: Object>(object: T, oldIndexPath: NSIndexPath, newIndexPath: NSIndexPath)
}

class Section<T: Object> : NSObject {
    var keyPath: String = ""
    var objects: NSMutableArray = []
    var sortDescriptors: [NSSortDescriptor] = []
    
    required init(keyPath: String, sortDescriptors: [NSSortDescriptor]) {
        self.keyPath = keyPath
        self.sortDescriptors = sortDescriptors
    }
    
    func insertSorted(object: T) -> Int {
        objects.addObject(object)
        objects.sortUsingDescriptors(sortDescriptors)
        return objects.indexOfObject(object)
    }
    
    func delete(object: T) -> Int {
        let index = objects.indexOfObject(object)
        if index < objects.count {
            objects.removeObject(object)
            return index
        }
        return -1
    }
    
    func deleteOutdatedObject(object: T) -> Int {
        let primaryKey = T.primaryKey()!
        let primaryKeyValue = (object as Object).valueForKey(primaryKey)!
        var objectToDelete: T?
        for sectionObject in objects{
            let value = sectionObject.valueForKey(primaryKey)!
            if value.isEqual(primaryKeyValue) {
                objectToDelete = sectionObject as? T
                break
            }
        }
        if let object = objectToDelete {
            return delete(object)
        }
        return -1
    }
}


class RealmResultsCache<T: Object> {
    var request: RealmRequest<T>
    var sections: [Section<T>] = []
    let defaultKeyPathValue = "default"
    var delegate: RealmResultsCacheDelegate?
    
    init(objects: [T], request: RealmRequest<T>) {
        self.request = request
        for object in objects {
            let section = sectionForObject(object)
            section.insertSorted(object)
        }
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
        delegate?.didInsertSection(index)
        return newSection
    }
    
    private func sectionForObject(object: T) -> Section<T> {
        var keyPathValue = defaultKeyPathValue
        if let keyPath = request.sectionKeyPath {
            keyPathValue = String(object.valueForKeyPath(keyPath))
        }
        return sectionForKeyPath(keyPathValue)
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
    
    func delete(objects: [T]) {
        for object in objects {
            let section = sectionForObject(object)
            let index = section.delete(object)
            guard index >= 0 else { return }
            let indexPath = NSIndexPath(forRow: index, inSection: indexForSection(section)!)
            delegate?.didDelete(object, indexPath: indexPath)
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