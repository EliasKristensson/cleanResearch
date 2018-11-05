//
//  CoreDataHelper.swift
//  cleanResearch
//
//  Created by Elias Kristensson on 2018-04-06.
//  Copyright © 2018 Elias Kristensson. All rights reserved.
//

import UIKit
import CoreData

class CoreDataHelper: NSObject {
    
    class func insertManagedObject(className: String, managedObjectContext: NSManagedObjectContext) -> AnyObject {
        let managedObject = NSEntityDescription.insertNewObject(forEntityName: className, into: managedObjectContext) as NSManagedObject
        return managedObjectContext
    }
    
    class func fetchEntities(className: String, managedObjectContext: NSManagedObjectContext, predicate: NSPredicate?) -> NSPersistentStoreResult {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>()
        let entityDescription = NSEntityDescription.entity(forEntityName: className, in: managedObjectContext)
        fetchRequest.entity = entityDescription
        
        if predicate != nil {
            fetchRequest.predicate = predicate!
        }
        
        var items = NSPersistentStoreResult()
        fetchRequest.returnsObjectsAsFaults = false
        do {
            items = try managedObjectContext.execute(fetchRequest)
        } catch {
            print(error)
        }
        return items

    }
    
}
