import XCTest

@testable
import XCEAssociatedStorage

import XCETesting

//===

class SimplyInitializableTests: XCTestCase
{
    class Owner
    {
        // ...
    }
    
    class Dependent: SimplyInitializable
    {
        required
        init()
        {
            // ...
        }
    }
    
    //===
    
    var associatedStorage: AssociatedStorage!
    
    //===
    
    override
    func setUp()
    {
        super.setUp()
        
        //===
        
        associatedStorage = AssociatedStorage()
        
    }
    
    override
    func tearDown()
    {
        associatedStorage = nil
        
        //===
        
        super.tearDown()
    }
    
    func testMain()
    {
        var owner: Owner? = Owner()
        
        //===
        
        RXC.isTrue("We start clean, with no entries stored."){
            
            associatedStorage?.storage.count == 0
        }
        
        //===
        
        let dependentForTheOwner: Dependent = associatedStorage.get(for: owner!)
        
        //===
        
        RXC.isTrue("We now should have one entry in the storage."){
            
            associatedStorage?.storage.count == 1
        }
        
        //===
        
        let dependentAgain: Dependent = associatedStorage.get(for: owner!)
        
        //===
        
        RXC.isTrue("Still must be one entry in the storage."){
            
            associatedStorage?.storage.count == 1
        }
        
        //===
        
        RXC.isTrue("First and second values must be identical."){
            
            dependentForTheOwner === dependentAgain
        }
        
        //===
        
        let exp = expectation(description: "Owner deallocated.")
        
        owner = nil // this will release associated object
        
        DispatchQueue.main.async {
            
            if
                self.associatedStorage?.storage.count != 0 // still NOT sero
            {
                
                // http://cocoamine.net/blog/2013/12/13/nsmaptable-and-zeroing-weak-references/
                
                exp.fulfill()
            }
        }
        
        waitForExpectations(timeout: 1.0)
    }
}
