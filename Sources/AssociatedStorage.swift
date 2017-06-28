import Foundation

//===

/**
 Conformance to this protocl guarantees that the type can be initialized on demand with simple `init()` constructor with no aprameters.
 */
public
protocol SimplyInitializable: class
{
    init()
}

//===

/**
 Conformance to this protocl guarantees that the type can be initialized on demand with constructor that takes the key object as the only parameter.
 */
public
protocol KeyObjectInitializable: class
{
    associatedtype Key: AnyObject
    
    init(with: Key)
}

//===

/**
 Key-value storage where value object will be automatically released when key object is deallocated.
 
 This storage for any given object of `Key` type (`keyObject`) allows to create and store one and only one instance of `Value` object type (`valueObject`). Each `valueObject`is lazy-initialized on first access and then being stored in the storage till the end of  corresponding `keyObject` life cycle. This special technique guarantees that the `valueObject` will be available while its `keyObject` is in memory, but, at the same time, will be released from memory as soon as its `keyObject` released, preventing memory leaks, but providing great convenience of dynamically extending any type storage capabiolities on demand.
 */
public
struct AssociatedStorage
{
    public
    init() { }
    
    /**
     Internal storage that actually stores the objects.
     
     - Note: The storage is initialized with `keyOptions` set to `weakMemory` and `valueOptions` set to `strongMemory`, which means each value is being kept in this collection as long as the object that is used as key is being kept in memory; as soon as the `key` object is deallocated the whole record automatically being removed from the storage.
     */
    var storage = NSMapTable<AnyObject, AnyObject>.weakToStrongObjects()
}

//=== MARK: SimplyInitializable value

public
extension AssociatedStorage
{
    /**
     Provides access to the value object, associated with given key object.
     
     Use as follows:
     
     ```swift
     let associatedStorage = AssociatedStorage()
     
     class Owner
     {
         // ...
     }
     
     class Dependent: SimplyInitializable
     {
        init()
        {
            // ...
        }
     }
     
     let owner: Owner = //... object that is being held in memory elsewhere
     
     let dependentForTheOwner: Dependent = associatedStorage.get(for: owner)
     
     // later:
     
     let dependentAgain: Dependent = associatedStorage.get(for: owner)
     
     // `dependentForTheOwner` is absolutely the same object as `dependentAgain`
     
     ```
     
     - Parameter keyObject: Object that is being held in memory somewhere and for which it's required to return associated object of type `Value`.
     
     - Returns: Object associated with given `keyObject`. This object is lazy-instantiated using `init()` constructor required by `SimplyInitializable` protocol.
     */
    func get<Key, Value>(for keyObject: Key) -> Value where
        Key: AnyObject,
        Value: SimplyInitializable
    {
        if
            let rawResult = storage.object(forKey: keyObject),
            let result = rawResult as? Value
        {
            return result
        }
        else
        {
            let result = Value()
            storage.setObject(result, forKey: keyObject)
            
            return result
        }
    }
}

//=== MARK: KeyObjectInitializable value

public
extension AssociatedStorage
{
    /**
     Provides access to value object, associated with given key object.
     
     Use as follows:
     
     ```swift
     let associatedStorage = AssociatedStorage()
     
     class Owner
     {
        // ...
     }
     
     class Dependent: KeyObjectInitializable
     {
        init(with keyObject: Owner)
        {
            //...
        }
     }
     
     let owner: Owner = // ... object that is being held in memory elsewhere
     
     let dependentForTheOwner: Dependent = associatedStorage.get(for: owner)
     
     // later:
     
     let dependentAgain: Dependent = associatedStorage.get(for: owner)
     
     // `dependentForTheOwner` is absolutely the same object as `dependentAgain`
     
     ```
     
     - Parameter keyObject: Object that is being held in memory somewhere and for which it's required to return associated object of type `Value`.
     
     - Returns: Object associated with given `keyObject`. This object is lazy-instantiated using `init(with: Key)` constructor required by `KeyObjectInitializable` protocol.
     */
    func get<Key, Value>(for keyObject: Key) -> Value where
        Key: AnyObject,
        Value: KeyObjectInitializable,
        Value.Key == Key
    {
        if
            let rawResult = storage.object(forKey: keyObject),
            let result = rawResult as? Value
        {
            return result
        }
        else
        {
            let result = Value(with: keyObject)
            storage.setObject(result, forKey: keyObject)
            
            return result
        }
    }
}

//=== MARK: Manually explicitly initializable value

public
extension AssociatedStorage
{
    /**
     Explicitly puts into storage given value object associated with given key object.
     
     Use as follows:
     
     ```swift
     let associatedStorage = AssociatedStorage()
     
     class Owner
     {
         // ...
     }
     
     class Dependent
     {
         // ...
     }
     
     let owner: Owner = // ... object that is being held in memory elsewhere
     
     let dependentForTheOwner: Dependent = // create somehow...
     
     associatedStorage.set(dependentForTheOwner, for: owner)
     
     let dependentAgain: Dependent? = associatedStorage.get(for: owner)
     
     // `dependentForTheOwner` is absolutely the same object as `dependentAgain`
     
     ```
     
     - Parameter valueObject: Object that must be stored as associtated value for `keyObject`.
     
     - Parameter keyObject: Object that is being held in memory somewhere and for which it's required to return associated object of type `Value`.
     */
    func set<Key, Value>(_ valueObject: Value, for keyObject: Key) where
        Key: AnyObject,
        Value: AnyObject
    {
        storage.setObject(valueObject, forKey: keyObject)
    }
    
    /**
     Provides access to value object, associated with given key object.
     
     Use as follows:
     
     ```swift
     let associatedStorage = AssociatedStorage()
     
     class Owner
     {
        // ...
     }
     
     class Dependent
     {
        // ...
     }
     
     let owner: Owner = // ... object that is being held in memory elsewhere
     
     let dependentForTheOwner: Dependent? = associatedStorage.get(for: owner)
     
     let dependentAgain: Dependent? = associatedStorage.get(for: owner)
     
     // `dependentForTheOwner` is the same object as `dependentAgain`,
     // or `nil` if associated object is not set yet
     
     ```
     
     - Parameter keyObject: Object that is being held in memory somewhere and for which it's required to return associated object of type `Value`.
     
     - Returns: Object associated with given `keyObject`, or `nil` if associated object is not set yet by `set(...)` function.
     */
    func get<Key, Value>(for keyObject: Key) -> Value? where
        Key: AnyObject,
        Value: AnyObject
    {
        if
            let rawResult = storage.object(forKey: keyObject),
            let result = rawResult as? Value
        {
            return result
        }
        else
        {
            return nil
        }
    }
}

//=== MARK: Explicitly initializable value via closure

public
extension AssociatedStorage
{
    /**
     Provides access to value object, associated with given key object.
     
     Use as follows:
     
     ```swift
     let associatedStorage = AssociatedStorage()
     
     class Owner
     {
         // ...
     }
     
     class Dependent
     {
         // ...
     }
     
     let owner: Owner = //... object that is being held in memory elsewhere
     
     let dependentForTheOwner: Dependent = associatedStorage.get(for: owner){ key in
     
         // ... create and return somehow an instance of Dependent here,
         // with or without usage of the `key` object;
         // this closure must be passed every time when access
         // value objects of type `Dependent` via this particular variation
         // of `get(...)` function, otherwise it's unclear how else to
         // instantiate `valueObject` on first access.
     }
     
     ```
     
     - Parameter keyObject: Object that is being held in memory somewhere and for which it's required to return associated object of type `Value`.
     
     - Returns: Object associated with given `keyObject`. This object is lazy-instantiated using `initialization` closure on first access.
     */
    func get<Key, Value>(
        for keyObject: Key,
        initialization: (Key) -> Value
        ) -> Value
        where
        Key: AnyObject,
        Value: AnyObject
    {
        if
            let rawResult = storage.object(forKey: keyObject),
            let result = rawResult as? Value
        {
            return result
        }
        else
        {
            let result = initialization(keyObject)
            storage.setObject(result, forKey: keyObject)
            
            return result
        }
    }
}
