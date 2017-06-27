import Foundation

//===

public
protocol SimplyInitializable: class
{
    init()
}

//===

public
protocol KeyObjectInitializable: class
{
    associatedtype Key: AnyObject
    
    init(with: Key)
}

//===

public
struct AssociatedStorage
{
    fileprivate
    var storage = NSMapTable<AnyObject, AnyObject>(
        keyOptions: .weakMemory,
        valueOptions: .strongMemory
    )
    
    public
    init() { }
}

//=== MARK: SimplyInitializable value

public
extension AssociatedStorage
{
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
    func set<Key, Value>(_ valueObject: Value, for keyObject: Key) where
        Key: AnyObject,
        Value: AnyObject
    {
        storage.setObject(valueObject, forKey: keyObject)
    }
    
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
