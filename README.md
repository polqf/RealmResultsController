![](Images/RRCHigh.png)

A NSFetchedResultsController implementation for Realm written in Swift

###Changelog:

- __0.0.1 Initial Release__ (14 Aug 2015)

###RoadMap:

- Open notifications for all realm changes

###Quick Start:

#### Create a RealmRequest:

The `RealmRequest<T>` needs 3 parameters:

- A Predicate
- A Realm DB
- Sort Descriptors

Where `T` is a `Realm` model



``` swift
let realm = // Your realm DB
let predicate = NSPredicate(format: "id != 0")
let sortDescriptors = [SortDescriptor(property: "projectID"), SortDescriptor(property: "name")]
let sectionKeypath = "projectID"
let request = RealmRequest<TaskModel>(predicate: predicate, realm: realm, sortDescriptors: sortDescriptors)
```

#### Create the RealmResultsController
The `RealmResultsController<T, U>` needs 3 parameters:

- A `RealmRequest<T>`
- The section key path (optional)
- A mapper like `func mapper(obj: T) -> U` (optional)

Where `T` is a `Realm` model and `U` is the type of the object you want to receive from the RRC.

__Note:__ `T` and `U` can be of the same type

:warning: - If the sectionKeyPath is not nil, it MUST match the first `SortDescriptor` of the `RealmRequest`. Otherwise it will raise an Exception.

:warning: 2 - Realm does not accept a `SortDescriptor`s that access a property of a relatonship. That limits the sectionKeyPath to be only a property of the current object


``` swift
let rrc = RealmResultsController<TaskModel, Task>(request: request, sectionKeyPath: sectionKeypath, mapper: Task.map)
rrc.delegate = self

// OR without mapper
let rrc = RealmResultsController<TaskModel, Task>(request: request, sectionKeyPath: sectionKeypath)
rrc.delegate = self
```

#### Implement the RealmResultsControllerDelegate methods

`RealmResultsControllerDelegate` has 4 methods that are required:

``` swift
func willChangeResults(controller: AnyObject)
func didChangeObject<U>(object: U, controller: AnyObject, oldIndexPath: NSIndexPath, newIndexPath: NSIndexPath, changeType: RealmResultsChangeType)
func didChangeSection<U>(section: RealmSection<U>, controller: AnyObject, index: Int, changeType: RealmResultsChangeType)
func didChangeResults(controller: AnyObject)
```

#####RealmResultsChangeType:
It an `enum` with four different types:

- Insert
- Delete
- Update
- Move

``` swift
enum RealmResultsChangeType: String {
    case Insert
    case Delete
    case Update
    case Move
}
```


#### Initial Fetch

In order to start receiving the `RealmResultsController` events, you need to do an initial fetch. After that you'll start receiving changes in the delegate methods

``` swift
rrc.performFetch()
```


### Important info:

####Methods to add/delete objects:

In order for the `RealmResultsController` to receive the change events in a Realm, you must use our custom methods. Those are declared in a Realm Extension and are wrappers for the original Realm methods

#####Add:
``` swift
public func addNotified<N: Object>(object: N, update: Bool = false)
public func addNotified<S: SequenceType where S.Generator.Element: Object>(objects: S, update: Bool = false)
public func createNotified<T: Object>(type: T.Type, value: AnyObject = [:], var update: Bool = false) -> T?
```
#####Delete:

``` swift
public func deleteNotified(object: Object)
public func deleteNotified<S: SequenceType where S.Generator.Element: Object>(objects: S)
```

####RealmRequest:

You can use a RealmRequest to retrieve the objects it is asking for without linking it to a RealmResultsController. It is going to return `Results<T>`

``` swift
let predicate = NSPredicate(format: "id != 0")
let sortDescriptors = [SortDescriptor(property: "projectID"), SortDescriptor(property: "name")]
let sectionKeypath = "projectID"
let request = RealmRequest<TaskModel>(predicate: predicate, realm: realm, sortDescriptors: sortDescriptors)

//Execute the request
let objects = request.execute()
```

You can also make a realm execute a certain request

```
let objects = realm.execute(request)

```

####Other methods added on the Realm Extension

#####ToArray()

In realm, when you ask for objects in the DB, you receive `Results<T>`
So, we added a the `toArray()` method to convert it to a common `Array<T>`:

``` swift
let objects = realm.objects(TaskModel.self).toArray()
```


### Demo:
<p align="center">
<img src="Images/RRCDemo.gif" height="300px"/>
</p>

###Installation:
####• CocoaPods

```
use_frameworks!
pod 'RealmResultsController', '~>0.0.1'
```

### Technical details:
- Swift 2.0 b4

###Licenses
All source code is licensed under the MIT License.

If you use it, we'll be happy to know about it.
