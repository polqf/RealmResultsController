//
//  testmodels.swift
//  RealmResultsController
//
//  Created by Isaac Roldan on 6/8/15.
//  Copyright © 2015 Redbooth.
//

import Foundation
import RealmSwift
import RealmResultsController
import Realm

class CarObject : Object
{
    dynamic var pictureURL : String = ""
    dynamic var modelName : String = ""
    dynamic var manufacturerName : String = ""
    dynamic var userName : String = ""
    dynamic var href : String = ""
    
    let distance : RealmOptional<Float> = RealmOptional<Float>()
    let price : RealmOptional<Float> = RealmOptional<Float>()
    
    let searchQueries : List<QueryModel> = List<QueryModel>()
    
    override init(value: AnyObject) {
        super.init(value: value)
    }
    
    required init() {
        super.init()
    }
    
    override init(realm: RLMRealm, schema: RLMObjectSchema) {
        super.init(realm: realm, schema: schema)
    }
    
    override static func primaryKey() -> String?
    {
        return "href"
    }
    
    class func resultsController() -> RealmResultsController<CarObject, CarObject>?
    {
        var resultsController : RealmResultsController<CarObject, CarObject>? = nil
        
        do
        {
            let realm : Realm = try Realm()
            let predicate : NSPredicate = NSPredicate(format: "href!=''")
            let request : RealmRequest = RealmRequest<CarObject>(predicate: predicate, realm: realm, sortDescriptors: [SortDescriptor(property: "manufacturerName")])
            
            resultsController = try RealmResultsController<CarObject, CarObject>(request: request, sectionKeyPath: nil)
        }
        catch
        {
            print("failed to create car object realm results controller")
        }
        
        return resultsController
    }
}

class QueryModel : Object
{
    dynamic var startDate : NSDate?
    dynamic var untilDate : NSDate?
    dynamic var location : String = ""
    
    dynamic var uniqueKey : String = ""
    
    let cars : List<CarObject> = List<CarObject>()
    
    convenience init(startDate : NSDate?, untilDate : NSDate?, location : String?)
    {
        self.init()
        self.startDate = startDate
        self.untilDate = untilDate
        self.location = location ?? ""
//        self.uniqueKey = (startDate?.completeDateString() ?? "") + (untilDate?.completeDateString() ?? "") + (location ?? "")
    }
    
    override static func primaryKey() -> String?
    {
        return "uniqueKey"
    }
}

