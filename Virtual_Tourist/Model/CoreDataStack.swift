//
//  CoreDataStack.swift
//  Virtual_Tourist
//
//  Created by scythe on 3/11/18.
//  Copyright © 2018 scythe. All rights reserved.
//

import Foundation
import CoreData

class CoreDataStack {

    //MARK: - Properties
    
//    private let model: NSManagedObjectModel
//    internal let coordinator : NSPersistentStoreCoordinator
//    private let modelURL: URL
//    internal let dbURL: URL
//    internal let persistentContext : NSManagedObjectContext
//    let context : NSManagedObjectContext
    
    private let modelName : String
    
    private lazy var model : NSManagedObjectModel = {
        guard let modelURL = Bundle.main.url(forResource: self.modelName, withExtension: "momd") else {
            fatalError("Unable To Find Data Model")
        }
        
        guard let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("unable to load Data Model")
        }
        
        return model
    }()
    
    private lazy var persistentCoordinator : NSPersistentStoreCoordinator = {
        //Initialize Persistent Store Coordinator
        let persistentCoordinator = NSPersistentStoreCoordinator(managedObjectModel: self.model)
        
        let storeName = "\(self.modelName)"
        
        // URL Documents Directory
        let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        print(documentsDirectoryURL!)
        // URL Persistent Store
        let persistentStoreURL = documentsDirectoryURL?.appendingPathComponent(storeName)
        
        do{
            let options = [NSMigratePersistentStoresAutomaticallyOption: true , NSInferMappingModelAutomaticallyOption : true]
            
            // Add Persistent Store
            try persistentCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: persistentStoreURL, options: options)
        }catch{
            fatalError("Unable To Add Persistent Store")
        }
        
        return persistentCoordinator
    }()
    
    //MARK - Context's
    private lazy var persistentContext : NSManagedObjectContext = {
        
        let persistentContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        persistentContext.persistentStoreCoordinator = persistentCoordinator
        
        return persistentContext
    }()
    
    private(set) lazy var mainContext : NSManagedObjectContext = {
        
        let mainContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        mainContext.parent = persistentContext
        return mainContext
    }()
    
    //MARK: - Initializers
    
    init?(modelName: String){
        
        self.modelName = modelName
        setupNotificationsHandling()
    }
    
    private func setupNotificationsHandling(){
        NotificationCenter.default.addObserver(self, selector:#selector(saveChanges(notification:)), name: .UIApplicationWillTerminate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(saveChanges(notification:)), name: .UIApplicationDidEnterBackground, object: nil)
    }
    
    @objc private func saveChanges(notification:Notification){
        saveChanges()
        print("Save")
    }
    
    func saveChanges(){
        
        mainContext.performAndWait {
            print("In saveChanges")
            do{
                if self.mainContext.hasChanges{
                    try self.mainContext.save()
                }
            }catch{
                print("Unable To save Changes to the MainContext")
                print("\(error) , \(error.localizedDescription)")
            }
            
            self.persistentContext.perform {
                
                do{
                    if self.persistentContext.hasChanges{
                        try self.persistentContext.save()
                        print("Finish savePersistent")
                    }
                }catch{
                    print("Unable To Save Changes to Persistent Context")
                    print("\(error) , \(error.localizedDescription)")
                }
            }
            
        }
    }
    
    
    //MARK: - FetchRequest with sort destriptors
    func fetch(objects entityName: String , from context:NSManagedObjectContext,withSortDesciptorKey key: String? , ascending : Bool? , withCompletion: @escaping (_ results: [Any]?) -> ()) {
        
        print("fetch")
        context.performAndWait {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
            if key == nil || ascending == nil {
                fetchRequest.sortDescriptors = []
            }else{
                fetchRequest.sortDescriptors = [NSSortDescriptor(key: key!, ascending: ascending!)]
            }
            
            
            do{
                if let results:[Any] = try context.fetch(fetchRequest) as [Any]?{
                    withCompletion(results)
                }else{
                    withCompletion(nil)
                }
            }catch{
                print("Unable to Fetch Results")
                print("\(error) , \(error.localizedDescription)")
                withCompletion(nil)
            }
        }
        
    }
    
    
    //MARK: - Deletes a Object
    func deleteCoreDataObject(object name : NSManagedObject , from context : NSManagedObjectContext){
        context.performAndWait {
            context.delete(name)
            saveChanges()
        }
    }
    
    func deleteAllObjectsOfEntity(entityName : String , in context : NSManagedObjectContext){
        
        //TODO: Check NSBatchDeteleRequest
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        
        context.performAndWait {
            do{
                let results = try context.fetch(fetchRequest)
                for result in results {
                    context.delete(result as! NSManagedObject)
                }
                print("All Object of entityName :\(entityName) are deleted successfully ")
                
            }catch{
                print("Unable to Delete All Objects from entity: \(entityName)")
                print("\(error) , \(error.localizedDescription)")
            }

        }
        
    }
    
    
    
    
    
    
}
